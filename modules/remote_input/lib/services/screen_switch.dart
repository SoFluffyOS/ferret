import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protocol/protocol.dart' show Platform;
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/capture_translator.dart';
import 'package:remote_input/services/control_client.dart';
import 'package:remote_input/services/input_codec.dart';

/// One keyboard and mouse for several computers, from this Mac: ⌃⌥→ sends
/// them to the next connected computer that takes them, ⌃⌥⎋ brings them
/// back, and so does losing that computer. While they are away, this Mac's
/// own pointer and keys are held back, so nothing types here.
class ScreenSwitch {
  ScreenSwitch({
    required FeatureHost host,
    required String featureId,
    required ControlClient client,
    required RemoteInputSettings settings,
    required InputCapture Function() capture,
    DateTime Function()? clock,
  }) : _host = host,
       _featureId = featureId,
       _client = client,
       _settings = settings,
       _createCapture = capture,
       _clock = clock ?? DateTime.now;

  /// Flag in `FeatureSupport`: this computer takes another computer's
  /// keyboard and mouse.
  static const screenFlag = 'screen';

  final FeatureHost _host;
  final String _featureId;
  final ControlClient _client;
  final RemoteInputSettings _settings;
  final InputCapture Function() _createCapture;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  InputCapture? _capture;
  ScreenSwitchState _state = .home;
  CaptureAccess? _access;
  CaptureTranslator _translator = CaptureTranslator();
  bool _keysTaken = false;
  bool _switching = false;
  bool _entering = false;

  ScreenSwitchState get state => _state;

  bool get enabled => _settings.screenSwitch;

  /// Input Monitoring and Accessibility, as last checked; null before.
  CaptureAccess? get access => _access;

  /// Another app holds ⌃⌥→ or ⌃⌥⎋.
  bool get keysTaken => _keysTaken;

  Stream<void> get changes => _changes.stream;

  Future<void> start() async {
    _subscriptions
      ..add(_client.changes.listen((_) => unawaited(_onClient())))
      ..add(
        _settings.changes
            .where((key) => key == RemoteInputSettings.screenSwitchKey)
            .listen((_) => unawaited(_apply())),
      );
    await _apply();
  }

  /// Turns the switch keys on or off. Turning on asks for access right
  /// away, since that is when the person wants it.
  Future<void> setEnabled(bool value) async {
    await _settings.setScreenSwitch(value);
    if (value) {
      await _ensureAccess();
    }
  }

  /// Checks Input Monitoring and Accessibility again, such as when the app
  /// comes back from System Settings.
  Future<CaptureAccess?> checkAccess() async {
    final capture = _capture;
    if (capture == null) {
      return null;
    }

    try {
      _access = await capture.access();
    } on Object catch (error) {
      printWarning('Could not check keyboard and mouse access', error);
    }

    _emit();
    return _access;
  }

  /// Asks for the access still missing: the system prompts the first time,
  /// System Settings after that.
  Future<CaptureAccess?> requestAccess() async {
    final capture = _capture ??= _subscribeTo(_createCapture());
    try {
      if (_settings.captureAsked) {
        await capture.openAccessSettings();
      } else {
        await _settings.setCaptureAsked(true);
        await capture.requestAccess();
      }

      _access = await capture.access();
    } on Object catch (error) {
      printWarning('Could not ask for keyboard and mouse access', error);
    }

    _emit();
    return _access;
  }

  /// Computers that take this Mac's keyboard and mouse, connected now, by
  /// name.
  List<Session> get targets =>
      _host.sessions
          .where(
            (session) =>
                session.remoteFeature(_featureId)?.flags.contains(screenFlag) ??
                false,
          )
          .toList()
        ..sort(
          (first, second) => _host
              .displayNameOf(first.remoteDeviceId)
              .toLowerCase()
              .compareTo(
                _host.displayNameOf(second.remoteDeviceId).toLowerCase(),
              ),
        );

  /// ⌃⌥→: the next computer, or back here after the last one.
  Future<void> next() async {
    if (!enabled || _switching || _state.phase == .asking) {
      return;
    }

    final targets = this.targets;
    if (targets.isEmpty) {
      _problem(.noComputer);
      return;
    }

    final currentId = switch (_state.phase) {
      .away => _state.deviceId,
      _ => null,
    };
    final index =
        targets.indexWhere((session) => session.remoteDeviceId == currentId) +
        1;
    if (currentId != null && index >= targets.length) {
      await home();
      return;
    }

    await goTo(targets[index % targets.length].remoteDeviceId);
  }

  /// Sends the keyboard and mouse to [deviceId].
  Future<void> goTo(String deviceId) async {
    if (!enabled || _switching) {
      return;
    }

    _switching = true;
    try {
      await _goTo(deviceId);
    } finally {
      _switching = false;
    }
  }

  /// ⌃⌥⎋: the keyboard and mouse come back to this Mac.
  Future<void> home() => _bringHome();

  Future<void> dispose() async {
    await _bringHome();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    if (_capture case final capture?) {
      await _quietly(() => capture.setSwitchKeys(enabled: false));
    }

    await _changes.close();
  }

  Future<void> _goTo(String deviceId) async {
    if (!await _ensureAccess()) {
      _problem(.needsAccess);
      return;
    }

    final capture = _capture;
    if (capture == null) {
      return;
    }

    if (await _quietly(capture.secureInputOn) ?? false) {
      _problem(.secureInput, deviceId: deviceId);
      return;
    }

    if (_state.isAway) {
      if (_state.deviceId == deviceId) {
        return;
      }

      await _leave();
    }

    _set(
      ScreenSwitchState(
        phase: .asking,
        deviceId: deviceId,
        deviceName: _host.displayNameOf(deviceId),
        at: _clock(),
      ),
    );
    await _client.start(deviceId);
    await _onClient();
  }

  Future<bool> _ensureAccess() async {
    _capture ??= _subscribeTo(_createCapture());
    final access = await checkAccess();
    if (access?.isGranted ?? false) {
      return true;
    }

    final asked = await requestAccess();
    return asked?.isGranted ?? false;
  }

  /// Follows the control: entered once granted, home when it ends.
  Future<void> _onClient() async {
    final state = _state;
    final deviceId = state.deviceId;
    if (deviceId == null || state.phase == .home) {
      return;
    }

    final current = _client.current;
    final isOurs = current != null && current.deviceId == deviceId;
    if (state.phase == .asking) {
      if (!isOurs) {
        return;
      }

      switch (current.phase) {
        case .active:
          if (_entering) {
            return;
          }

          _entering = true;
          try {
            await _enter(deviceId);
          } finally {
            _entering = false;
          }
        case .requesting || .waitingForConsent:
          return;
        case .denied:
          _problem(.denied, deviceId: deviceId, denial: current.denial);
        case .stopped:
          _problem(.stopped, deviceId: deviceId);
        case .lostConnection || .unreachable:
          _problem(.lostConnection, deviceId: deviceId);
      }

      return;
    }

    if (isOurs && current.isActive) {
      return;
    }

    final problem = switch (current?.phase) {
      .stopped => ScreenSwitchProblem.stopped,
      _ => ScreenSwitchProblem.lostConnection,
    };
    await _bringHome(problem: problem);
  }

  Future<void> _enter(String deviceId) async {
    final capture = _capture;
    if (capture == null) {
      return;
    }

    final held = await _quietly(capture.start);
    if (held == null) {
      final secure = await _quietly(capture.secureInputOn) ?? false;
      await _client.stop();
      _problem(switch (secure) {
        true => .secureInput,
        false => .captureFailed,
      }, deviceId: deviceId);
      return;
    }

    final current = _client.current;
    if (_state.phase != .asking ||
        _state.deviceId != deviceId ||
        current == null ||
        current.deviceId != deviceId ||
        !current.isActive) {
      await _quietly(capture.stop);
      return;
    }

    final platform = _host.sessionFor(deviceId)?.remoteDevice?.platform;
    _translator = CaptureTranslator(
      swapCommandAndControl: platform != Platform.PLATFORM_MACOS,
    );
    _client.add(InputCodec.enter(_translator.enter(held)));
    _set(
      ScreenSwitchState(
        phase: .away,
        deviceId: deviceId,
        deviceName: _host.displayNameOf(deviceId),
        at: _clock(),
      ),
    );
  }

  /// Gives the keyboard and mouse back here, and tells the other computer
  /// to let go of anything held. The control itself stays, so the next
  /// switch is instant.
  Future<void> _leave() async {
    _set(.home);
    _client
      ..add(InputCodec.leave())
      ..flush();
    if (_capture case final capture?) {
      await _quietly(capture.stop);
    }
  }

  Future<void> _bringHome({ScreenSwitchProblem? problem}) async {
    final state = _state;
    switch (state.phase) {
      case .home:
        return;
      case .asking:
        _set(.home);
        await _client.stop();
      case .away:
        await _leave();
    }

    if (problem != null) {
      _problem(problem, deviceId: state.deviceId);
    }
  }

  void _problem(
    ScreenSwitchProblem problem, {
    String? deviceId,
    OutgoingDenial? denial,
  }) {
    _set(
      ScreenSwitchState(
        phase: .home,
        deviceId: deviceId,
        deviceName: switch (deviceId) {
          final id? => _host.displayNameOf(id),
          null => '',
        },
        problem: problem,
        denial: denial,
        at: _clock(),
      ),
    );
  }

  /// Forgets the last problem, once the person saw it.
  void dismissProblem() {
    if (_state.problem == null) {
      return;
    }

    _set(.home);
  }

  Future<void> _apply() async {
    if (!enabled) {
      await _bringHome();
      if (_capture case final capture?) {
        await _quietly(() => capture.setSwitchKeys(enabled: false));
      }

      _keysTaken = false;
      _emit();
      return;
    }

    final capture = _capture ??= _subscribeTo(_createCapture());
    final registered = await _quietly(
      () => capture.setSwitchKeys(enabled: true),
    );
    _keysTaken = registered == false;
    await checkAccess();
  }

  InputCapture _subscribeTo(InputCapture capture) {
    _subscriptions
      ..add(capture.events.listen(_onCaptured))
      ..add(capture.switchKeys.listen((key) => unawaited(_onSwitchKey(key))))
      ..add(capture.ends.listen((end) => unawaited(_onEnded(end))));
    return capture;
  }

  void _onCaptured(List<NativeCapturedEvent> events) {
    if (!_state.isAway) {
      return;
    }

    for (final event in events) {
      _translator.translate(event, _client);
    }
  }

  Future<void> _onSwitchKey(NativeSwitchKey key) => switch (key) {
    .next => next(),
    .home => home(),
  };

  Future<void> _onEnded(NativeCaptureEnd end) => _bringHome(
    problem: switch (end) {
      .homeKey => null,
      .secureInput => .secureInput,
      .tapFailed => .captureFailed,
    },
  );

  Future<T?> _quietly<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      printWarning('Keyboard and mouse switch failed', error);
      return null;
    }
  }

  void _set(ScreenSwitchState state) {
    _state = state;
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
