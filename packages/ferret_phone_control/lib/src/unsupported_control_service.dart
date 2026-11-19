import 'package:ferret_phone_control/src/control_service.dart';

/// Everywhere but Android: there is no service to turn on.
class UnsupportedControlService implements ControlService {
  const UnsupportedControlService();

  @override
  Future<bool> isEnabled() async => false;

  @override
  Stream<bool> get enabledChanges => const Stream.empty();

  @override
  Future<bool> openSettings() async => false;

  @override
  Future<void> setArmed(bool armed) async {}

  @override
  Future<bool> touch(ServiceTouch action, double x, double y) async => false;

  @override
  Future<bool> scroll(
    double x,
    double y,
    double horizontal,
    double vertical,
  ) async => false;

  @override
  Future<bool> typeText(String text) async => false;

  @override
  Future<bool> pressKey(ServiceKey key) async => false;

  @override
  Future<bool> pressButton(ServiceButton button) async => false;
}
