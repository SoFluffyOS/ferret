import 'package:ferret_actions/src/input_idle.dart';

/// Phones and anything else: no keyboard to watch.
class UnsupportedInputIdle implements InputIdle {
  const UnsupportedInputIdle();

  @override
  Future<Duration?> idleTime() async => null;
}
