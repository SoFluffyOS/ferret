import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = [Locale('en'), Locale('vi')];

  tearDown(() => AppLocale.chosen.value = null);

  test('a language picked in Settings wins over the system', () {
    AppLocale.chosen.value = const Locale('vi');

    expect(AppLocale.pick(supported), const Locale('vi'));
  });

  test('a language Ferret has no strings for falls back to English', () {
    AppLocale.chosen.value = const Locale('ar');

    expect(AppLocale.pick(supported), const Locale('en'));
  });

  test('a regional tag still finds its language', () {
    AppLocale.chosen.value = const Locale('vi', 'VN');

    expect(AppLocale.pick(supported), const Locale('vi'));
  });

  test('stored tags parse, and empty follows the system', () {
    expect(AppLocale.parse('vi'), const Locale('vi'));
    expect(AppLocale.parse('pt-BR'), const Locale('pt', 'BR'));
    expect(AppLocale.parse(''), isNull);
    expect(AppLocale.parse(null), isNull);
  });
}
