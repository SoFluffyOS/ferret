import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

void main() {
  test('codes next to a word that says so are found', () {
    for (final text in [
      'Your verification code is 482913',
      'G-482913 is your Google verification code.',
      'Use 4829 to sign in',
      'Your OTP: 482 913',
      'Código de verificación: 482-913',
      'Ваш код: 482913',
    ]) {
      expect(OneTimeCode.isIn(text), isTrue, reason: text);
    }
  });

  test('ordinary numbers stay', () {
    for (final text in [
      'Meet at 1930?',
      'Your order 48291 shipped',
      'Code review at 3 pm',
      'Pin the 12.50 receipt',
      'Call me on 2024-11-19 about the code',
      'Login from Chrome on Mac',
      'Your order 48291 is confirmed',
    ]) {
      expect(OneTimeCode.isIn(text), isFalse, reason: text);
    }
  });
}
