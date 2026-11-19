import 'package:calls/calls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strips what people type around the digits', () {
    expect(PhoneNumbers.dialable('+1 (555) 010-0100'), '+15550100100');
    expect(PhoneNumbers.dialable('555.0100'), '5550100');
    expect(PhoneNumbers.dialable('*123#'), '*123#');
  });

  test('refuses what a phone can not dial', () {
    expect(PhoneNumbers.dialable(''), isNull);
    expect(PhoneNumbers.dialable('   '), isNull);
    expect(PhoneNumbers.dialable('call mom'), isNull);
    expect(PhoneNumbers.dialable('555+0100'), isNull);
    expect(PhoneNumbers.dialable('tel:5550100'), isNull);
    expect(PhoneNumbers.dialable('1' * 40), isNull);
  });
}
