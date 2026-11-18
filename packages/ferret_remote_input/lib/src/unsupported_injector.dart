import 'package:ferret_remote_input/src/injector_status.dart';
import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/input_injector.dart';

/// Phones and tablets: they control other devices, they are never
/// controlled.
class UnsupportedInjector implements InputInjector {
  static const _status = InjectorStatus.unavailable(.platform);

  @override
  Future<InjectorStatus> status() async => _status;

  @override
  Future<InjectorStatus> requestAccess() async => _status;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> inject(List<InputAction> actions) async {}

  @override
  Future<void> releaseAll() async {}

  @override
  Future<void> dispose() async {}
}
