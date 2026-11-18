import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/models/models.dart';
import 'package:find/services/audio_guard.dart';
import 'package:protocol/find.dart';

/// Rings this device: starts and stops the platform alert, raises and
/// restores the volume, and stops on its own after the ring's duration.
/// Requests run one at a time, so two devices asking at once can't race.
class RingController {
  RingController({
    required FindPlatform platform,
    required FindSettings settings,
    RingTexts Function(String requesterName)? texts,
    DateTime Function()? clock,
  }) : _platform = platform,
       _settings = settings,
       _audio = AudioGuard(platform, settings),
       _texts = texts ?? RingTexts.english,
       _clock = clock ?? DateTime.now;

  static const defaultDuration = Duration(minutes: 2);
  static const minDuration = Duration(seconds: 5);
  static const maxDuration = Duration(minutes: 5);

  /// The platform stops on its own a little after the longest ring, in case
  /// the app never gets to.
  static const _platformLimit = Duration(minutes: 5, seconds: 10);

  final FindPlatform _platform;
  final FindSettings _settings;
  final AudioGuard _audio;
  final RingTexts Function(String requesterName) _texts;
  final DateTime Function() _clock;
  final StreamController<LocalRing> _changes = .broadcast();

  LocalRing _current = LocalRing.idle;
  RingAbilities _abilities = const RingAbilities();
  StreamSubscription<AlertStop>? _platformStops;
  Timer? _timer;
  Future<void>? _tail;

  LocalRing get current => _current;

  /// What this device can do, as last read with [refreshAbilities].
  RingAbilities get abilities => _abilities;

  Stream<LocalRing> get changes => _changes.stream;

  /// Puts back a volume a crash left raised, and reads the abilities.
  Future<void> start() async {
    _platformStops = _platform.stops.listen(_onPlatformStop);
    await _audio.restore();
    await refreshAbilities();
  }

  Future<RingAbilities> refreshAbilities() async {
    try {
      _abilities = await _platform.abilities();
    } on Object catch (error) {
      printWarning('Could not read what this device can do to ring', error);
    }

    return _abilities;
  }

  /// Rings for [duration] (the default when null), or extends a ring that is
  /// already going. Returns the state after.
  Future<LocalRing> ring({
    required String requesterId,
    required String requesterName,
    Duration? duration,
    bool overrideSilent = true,
  }) => _serial(
    () => _ring(requesterId, requesterName, _clamp(duration), overrideSilent),
  );

  /// Stops ringing for [reason]. Does nothing when not ringing.
  Future<LocalRing> stop(StopReason reason) => _serial(() => _stop(reason));

  Future<void> dispose() async {
    await stop(.STOP_REASON_STOPPED_REMOTELY);
    await _platformStops?.cancel();
    unawaited(_changes.close());
  }

  Future<LocalRing> _ring(
    String requesterId,
    String requesterName,
    Duration duration,
    bool overrideSilent,
  ) async {
    final now = _clock();
    if (_current.isRinging) {
      return _extend(requesterId, requesterName, now.add(duration));
    }

    final abilities = await refreshAbilities();
    final allowLoud = overrideSilent && _settings.ringOnSilent;
    final audio = await _audio.read();
    final muted =
        !allowLoud && !abilities.ignoresSilentSwitch && (audio?.quiet ?? false);

    if (allowLoud && abilities.controlsVolume) {
      await _audio.raise(
        audio,
        liftDoNotDisturb: abilities.dndAccessGranted,
      );
    }

    final texts = _texts(requesterName);
    try {
      await _platform.startAlert(
        RingAlert(
          title: texts.title,
          body: texts.body,
          foundItLabel: texts.foundIt,
          maxDuration: _platformLimit,
          silent: muted,
          flashTorch: _settings.flashTorch && abilities.hasTorch,
        ),
      );
    } on Object catch (error) {
      printWarning('Could not ring', error);
      await _stopPlatform();
      await _audio.restore();
      return _set(
        LocalRing(
          phase: .stopped,
          requesterIds: [requesterId],
          requesterName: requesterName,
          startedAt: now,
          reason: .STOP_REASON_FAILED,
        ),
      );
    }

    final endsAt = now.add(duration);
    _schedule(endsAt.difference(now));
    return _set(
      LocalRing(
        phase: .ringing,
        requesterIds: [requesterId],
        requesterName: requesterName,
        startedAt: now,
        endsAt: endsAt,
        muted: muted,
      ),
    );
  }

  /// A second request while ringing keeps it going longer, never beyond the
  /// longest ring from when it started.
  LocalRing _extend(String requesterId, String requesterName, DateTime wanted) {
    final startedAt = _current.startedAt ?? _clock();
    final latest = startedAt.add(maxDuration);
    final current = _current.endsAt ?? wanted;
    final later = switch (wanted.isAfter(current)) {
      true => wanted,
      false => current,
    };
    final endsAt = switch (later.isAfter(latest)) {
      true => latest,
      false => later,
    };

    _schedule(endsAt.difference(_clock()));
    return _set(
      _current.copyWith(
        requesterIds: {..._current.requesterIds, requesterId}.toList(),
        requesterName: requesterName,
        endsAt: endsAt,
      ),
    );
  }

  Future<LocalRing> _stop(StopReason reason) async {
    if (!_current.isRinging) {
      return _current;
    }

    _timer?.cancel();
    _timer = null;
    await _stopPlatform();
    await _audio.restore();
    return _set(_current.copyWith(phase: .stopped, reason: reason));
  }

  Future<void> _stopPlatform() async {
    try {
      await _platform.stopAlert();
    } on Object catch (error) {
      printWarning('Could not stop ringing', error);
    }
  }

  void _onPlatformStop(AlertStop stop) {
    final reason = switch (stop) {
      .found || .volumeKey => StopReason.STOP_REASON_FOUND,
      .timeout => StopReason.STOP_REASON_TIMEOUT,
    };
    unawaited(this.stop(reason));
  }

  void _schedule(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, () => unawaited(stop(.STOP_REASON_TIMEOUT)));
  }

  LocalRing _set(LocalRing ring) {
    _current = ring;
    if (!_changes.isClosed) {
      _changes.add(ring);
    }

    return ring;
  }

  Duration _clamp(Duration? duration) {
    final wanted = duration ?? defaultDuration;
    if (wanted < minDuration) {
      return minDuration;
    }

    if (wanted > maxDuration) {
      return maxDuration;
    }

    return wanted;
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = switch (_tail) {
      final previous? => previous.then((_) => action()),
      null => action(),
    };
    final tail = result.then<void>((_) {}, onError: (Object _) {});
    _tail = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_tail, tail)) {
          _tail = null;
        }
      }),
    );
    return result;
  }
}
