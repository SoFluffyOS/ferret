import 'dart:async';

import 'package:ferret_phone_control/src/control_service.dart';

/// The accessibility service in memory: tests turn it on and off, and it
/// records what it was asked to do, refusing it all unless armed, like the
/// real one.
class FakeControlService implements ControlService {
  FakeControlService({this.enabled = false});

  bool enabled;
  bool armed = false;

  /// What the focused field takes: false is a screen with no text field.
  bool hasTextField = true;

  /// What the service carried out, in order: `touch:down`, `scroll`,
  /// `text`, `key:copy`, `button:back`.
  final List<String> done = [];
  final List<String> typed = [];
  int settingsOpened = 0;

  final StreamController<bool> _enabled = .broadcast(sync: true);

  /// The owner flipped its switch in the system settings.
  void turn({required bool on}) {
    enabled = on;
    _enabled.add(on);
  }

  @override
  Stream<bool> get enabledChanges => _enabled.stream;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<void> setArmed(bool armed) async => this.armed = armed;

  @override
  Future<bool> touch(ServiceTouch action, double x, double y) async =>
      _did('touch:${action.name}');

  @override
  Future<bool> scroll(
    double x,
    double y,
    double horizontal,
    double vertical,
  ) async => _did('scroll');

  @override
  Future<bool> typeText(String text) async {
    if (!hasTextField || !_did('text')) {
      return false;
    }

    typed.add(text);
    return true;
  }

  @override
  Future<bool> pressKey(ServiceKey key) async => _did('key:${key.name}');

  @override
  Future<bool> pressButton(ServiceButton button) async =>
      _did('button:${button.name}');

  bool _did(String what) {
    if (!enabled || !armed) {
      return false;
    }

    done.add(what);
    return true;
  }
}
