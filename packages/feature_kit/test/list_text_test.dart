import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppLocale.chosen.value = null;
    AppLocale.supported = const [Locale('en')];
  });

  test('names are joined with the comma of the language', () {
    const names = ['Pixel 7', 'iPad'];

    expect(ListText.join(names, localeName: 'en'), 'Pixel 7, iPad');
    expect(ListText.join(names, localeName: 'vi'), 'Pixel 7, iPad');
    expect(ListText.join(names, localeName: 'ja'), 'Pixel 7、iPad');
    expect(ListText.join(names, localeName: 'zh_TW'), 'Pixel 7、iPad');
    expect(ListText.join(names, localeName: 'ar'), 'Pixel 7، iPad');
  });

  test('one name stays as it is', () {
    expect(ListText.join(['Pixel 7'], localeName: 'ja'), 'Pixel 7');
  });

  test('without a language it follows the one Ferret shows, not one it has '
      'no strings for', () {
    AppLocale.chosen.value = const Locale('ja');

    expect(ListText.join(['a', 'b']), 'a, b');

    AppLocale.supported = const [Locale('en'), Locale('ja')];

    expect(ListText.join(['a', 'b']), 'a、b');
  });
}
