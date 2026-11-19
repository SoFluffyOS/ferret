import 'dart:async';
import 'dart:io';

import 'package:ferret_system/src/ferret_system.dart';
import 'package:ferret_system/src/session/logind_session_source.dart';
import 'package:ferret_system/src/session/polling_session_source.dart';
import 'package:ferret_system/src/session/screen_session_source.dart';
import 'package:ferret_system/src/session/windows_session_probe.dart';

/// Whether the person is at this computer: the screen is unlocked and this
/// account is the one in front. On a computer several people share, a
/// locked screen or a switch to another account means someone else may be
/// looking, so private previews stop showing.
class ScreenSession {
  ScreenSession(this._source);

  /// The watcher for this platform: macOS's own notifications, Windows'
  /// input desktop, Linux's logind; always active elsewhere.
  factory ScreenSession.forPlatform() {
    if (Platform.isMacOS) {
      return ScreenSession(_MacSessionSource(FerretSystem()));
    }

    if (Platform.isWindows) {
      return ScreenSession(
        PollingSessionSource(probe: WindowsSessionProbe().isActive),
      );
    }

    if (Platform.isLinux) {
      return ScreenSession(LogindSessionSource());
    }

    return ScreenSession(const AlwaysActiveSource());
  }

  final ScreenSessionSource _source;
  final StreamController<bool> _changes = .broadcast();
  StreamSubscription<bool>? _subscription;
  bool _active = true;

  bool get isActive => _active;

  /// Each time [isActive] flips.
  Stream<bool> get changes => _changes.stream;

  Future<void> start() async {
    if (_subscription != null) {
      return;
    }

    _subscription = _source.changes.listen(_set);
    await _source.start();
    _set(await _source.isActive());
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _source.stop();
  }

  void _set(bool active) {
    if (active == _active) {
      return;
    }

    _active = active;
    _changes.add(active);
  }
}

class _MacSessionSource implements ScreenSessionSource {
  _MacSessionSource(this._system);

  final FerretSystem _system;

  @override
  Future<bool> isActive() => _system.isScreenSessionActive();

  @override
  Stream<bool> get changes => _system.screenSessionChanges;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
