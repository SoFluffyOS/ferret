import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lengths read as m:ss, then h:mm:ss from one hour', () {
    expect(ClockText.duration(const Duration(seconds: 5)), '0:05');
    expect(ClockText.duration(const Duration(seconds: 125)), '2:05');
    expect(ClockText.duration(const Duration(seconds: 3725)), '1:02:05');
    expect(ClockText.duration(const Duration(seconds: -3)), '0:00');
  });

  test('a time of day in a locale without date symbols still shows', () {
    final at = DateTime(2026, 11, 19, 15, 7);

    expect(ClockText.timeOfDay('en_US', at), '3:07\u202fPM');
    expect(ClockText.timeOfDay('xx', at), '15:07');
  });
}
