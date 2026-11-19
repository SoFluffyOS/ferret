import 'dart:async';

import 'package:ferret_phone_control/src/control_service.dart';
import 'package:ferret_phone_control/src/messages.g.dart';

/// The accessibility service through the plugin.
class PigeonControlService implements ControlService, ControlServiceFlutterApi {
  PigeonControlService({ControlServiceHostApi? api})
    : _api = api ?? ControlServiceHostApi() {
    ControlServiceFlutterApi.setUp(this);
  }

  final ControlServiceHostApi _api;
  final StreamController<bool> _enabled = .broadcast();

  @override
  Stream<bool> get enabledChanges => _enabled.stream;

  @override
  void onEnabledChanged(bool enabled) => _enabled.add(enabled);

  @override
  Future<bool> isEnabled() => _api.isEnabled();

  @override
  Future<bool> openSettings() => _api.openSettings();

  @override
  Future<void> setArmed(bool armed) => _api.setArmed(armed);

  @override
  Future<bool> touch(ServiceTouch action, double x, double y) =>
      _api.touch(action, x, y);

  @override
  Future<bool> scroll(double x, double y, double horizontal, double vertical) =>
      _api.scroll(x, y, horizontal, vertical);

  @override
  Future<bool> typeText(String text) => _api.typeText(text);

  @override
  Future<bool> pressKey(ServiceKey key) => _api.pressKey(key);

  @override
  Future<bool> pressButton(ServiceButton button) => _api.pressButton(button);
}
