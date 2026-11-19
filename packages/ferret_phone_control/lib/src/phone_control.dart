import 'dart:async';
import 'dart:io';

import 'package:ferret_phone_control/src/android_keys.dart';
import 'package:ferret_phone_control/src/control_path.dart';
import 'package:ferret_phone_control/src/control_service.dart';
import 'package:ferret_phone_control/src/phone_button.dart';
import 'package:ferret_phone_control/src/pigeon_control_service.dart';
import 'package:ferret_phone_control/src/unsupported_control_service.dart';
import 'package:ferret_power/ferret_power.dart';

/// The one door through which a computer acts on this phone.
///
/// It picks the way by itself: the power-ups helper when Shizuku or root is
/// on, else Ferret's accessibility service when its owner turned it on,
/// else nothing. Everything is refused until [arm], and again after
/// [disarm]: the caller arms it only while a computer it was allowed to
/// let in is shown the screen.
class PhoneControl {
  PhoneControl({
    PowerCapabilities? power,
    ControlService? service,
    bool? supported,
  }) : _power = power ?? PowerCapabilities(),
       _service = service ?? _serviceHere(),
       isSupported = supported ?? Platform.isAndroid;

  static ControlService _serviceHere() {
    if (Platform.isAndroid) {
      return PigeonControlService();
    }

    return const UnsupportedControlService();
  }

  /// Whether this kind of device can be controlled at all. An iPhone
  /// can't: iOS lets no app act on another.
  final bool isSupported;

  final PowerCapabilities _power;
  final ControlService _service;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _serviceEnabled = false;
  bool _armed = false;
  bool _serviceArmed = false;

  /// Fires when [path] may have changed.
  Stream<void> get changes => _changes.stream;

  /// The owner turned Ferret's accessibility service on.
  bool get serviceEnabled => _serviceEnabled;

  bool get isArmed => _armed;

  ControlPath get path {
    if (!isSupported) {
      return .none;
    }

    if (_power.canInjectInput) {
      return .powerUps;
    }

    if (_serviceEnabled) {
      return .service;
    }

    return .none;
  }

  /// What a computer can do here right now.
  Set<PhoneAbility> get abilities => switch (path) {
    .none => const {},
    _ => const {.pointer, .keys, .text, .buttons},
  };

  List<PhoneButton> get buttons => switch (path) {
    .none => const [],
    _ => PhoneButton.values,
  };

  /// Reads whether the service is on and follows both ways from then on.
  Future<void> start() async {
    if (!isSupported) {
      return;
    }

    _subscriptions
      ..add(_service.enabledChanges.listen(_onServiceEnabled))
      ..add(_power.tierChanges.listen((_) => _onPathChanged()));
    _serviceEnabled = await _guarded(_service.isEnabled);
  }

  /// Opens the system's Accessibility settings on Ferret's row.
  Future<bool> openServiceSettings() => _guarded(_service.openSettings);

  /// Lets a computer act through [path], until [disarm].
  Future<void> arm() async {
    _armed = true;
    await _syncService();
  }

  /// Refuses everything again and lifts a finger left down.
  Future<void> disarm() async {
    if (!_armed) {
      return;
    }

    _armed = false;
    await _syncService();
    if (_power.canInjectInput) {
      await _power.releaseInput();
    }
  }

  /// A finger at ([x], [y]): fractions of the screen as it is turned now.
  Future<bool> touch(TouchAction action, double x, double y) => _act(
    powerUps: () => _power.inject(PowerTouch(action, x, y)),
    service: () => _service.touch(
      switch (action) {
        .down => .down,
        .move => .move,
        .up => .up,
        .cancel => .cancel,
      },
      x,
      y,
    ),
  );

  /// What is under ([x], [y]) scrolls by wheel notches: positive
  /// [horizontal] is right, positive [vertical] is down.
  Future<bool> scroll(
    double x,
    double y, {
    double horizontal = 0,
    double vertical = 0,
  }) => _act(
    powerUps: () => _power.inject(
      PowerScroll(x, y, horizontal: horizontal, vertical: -vertical),
    ),
    service: () => _service.scroll(x, y, horizontal, vertical),
  );

  /// An Android key ([AndroidKeys]) going down or up. The service only
  /// stands in for some keys, on their way down.
  Future<bool> key(int keyCode, {required bool down, int metaState = 0}) =>
      _act(
        powerUps: () => _power.inject(
          PowerKey(keyCode, down: down, metaState: metaState),
        ),
        service: () async {
          if (!down) {
            return true;
          }

          if (keyCode == AndroidKeys.space && metaState == 0) {
            return _service.typeText(' ');
          }

          final serviceKey = AndroidKeys.serviceKeyOf(keyCode, metaState);
          if (serviceKey == null) {
            return false;
          }

          return _service.pressKey(serviceKey);
        },
      );

  Future<bool> text(String text) => _act(
    powerUps: () => _power.inject(PowerText(text)),
    service: () => _service.typeText(text),
  );

  Future<bool> press(PhoneButton button) => _act(
    powerUps: () async {
      final keyCode = switch (button) {
        .back => AndroidKeys.back,
        .home => AndroidKeys.home,
        .recents => AndroidKeys.appSwitch,
        .notifications => AndroidKeys.notification,
        .power => AndroidKeys.power,
        .volumeUp => AndroidKeys.volumeUp,
        .volumeDown => AndroidKeys.volumeDown,
      };
      final pressed = await _power.inject(PowerKey(keyCode, down: true));
      final released = await _power.inject(PowerKey(keyCode, down: false));
      return pressed && released;
    },
    service: () => _service.pressButton(switch (button) {
      .back => .back,
      .home => .home,
      .recents => .recents,
      .notifications => .notifications,
      .power => .lockScreen,
      .volumeUp => .volumeUp,
      .volumeDown => .volumeDown,
    }),
  );

  Future<void> dispose() async {
    await disarm();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    await _changes.close();
  }

  Future<bool> _act({
    required Future<bool> Function() powerUps,
    required Future<bool> Function() service,
  }) async {
    if (!_armed) {
      return false;
    }

    return switch (path) {
      .powerUps => _guarded(powerUps),
      .service => _guarded(service),
      .none => false,
    };
  }

  void _onServiceEnabled(bool enabled) {
    _serviceEnabled = enabled;
    _onPathChanged();
  }

  void _onPathChanged() {
    unawaited(_syncService());
    _changes.add(null);
  }

  /// The service listens to the screen only while it is the way in use.
  Future<void> _syncService() async {
    final wanted = _armed && path == .service;
    if (wanted == _serviceArmed) {
      return;
    }

    _serviceArmed = wanted;
    try {
      await _service.setArmed(wanted);
    } on Object {
      _serviceArmed = false;
    }
  }

  Future<bool> _guarded(Future<bool> Function() call) async {
    try {
      return await call();
    } on Object {
      return false;
    }
  }
}
