import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editing keys map to what the service does in a text field', () {
    expect(AndroidKeys.serviceKeyOf(AndroidKeys.enter, 0), ServiceKey.enter);
    expect(
      AndroidKeys.serviceKeyOf(AndroidKeys.backspace, 0),
      ServiceKey.backspace,
    );
    expect(
      AndroidKeys.serviceKeyOf(AndroidKeys.forwardDelete, 0),
      ServiceKey.delete,
    );
    expect(AndroidKeys.serviceKeyOf(AndroidKeys.moveHome, 0), ServiceKey.home);
    expect(AndroidKeys.serviceKeyOf(AndroidKeys.moveEnd, 0), ServiceKey.end);
  });

  test('Control with a letter is a shortcut, other letters are nothing', () {
    expect(
      AndroidKeys.serviceKeyOf(AndroidKeys.a, AndroidKeys.metaCtrl),
      ServiceKey.selectAll,
    );
    expect(AndroidKeys.serviceKeyOf(AndroidKeys.a, 0), isNull);
    expect(
      AndroidKeys.serviceKeyOf(AndroidKeys.enter, AndroidKeys.metaCtrl),
      isNull,
    );
  });
}
