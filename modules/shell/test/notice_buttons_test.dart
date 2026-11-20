import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/notice_buttons.dart';

void main() {
  const allow = NoticeAction(id: 'allow', label: 'Allow', opensApp: true);
  const deny = NoticeAction(id: 'deny', label: "Don't allow");
  const reply = NoticeAction(id: 'reply', label: 'Reply', isReply: true);

  group('Android', () {
    test('a button that opens the app starts its activity', () {
      final button = androidButton(allow);

      expect(button.id, 'allow');
      expect(button.title, 'Allow');
      expect(button.showsUserInterface, isTrue);
    });

    test('any other button works in the background', () {
      expect(androidButton(deny).showsUserInterface, isFalse);
      expect(androidButton(reply).showsUserInterface, isFalse);
    });

    test('a reply asks for text', () {
      expect(androidButton(reply).inputs.single.label, 'Reply');
      expect(androidButton(deny).inputs, isEmpty);
    });
  });

  group('iPhone and Mac', () {
    test('a button that opens the app brings it to the front', () {
      final button = darwinButton(allow);

      expect(button.identifier, 'allow');
      expect(button.options, {DarwinNotificationActionOption.foreground});
    });

    test('any other button stays in the background', () {
      expect(darwinButton(deny).options, isEmpty);
      expect(darwinButton(reply).options, isEmpty);
    });

    test('a reply asks for text', () {
      expect(darwinButton(reply).placeholder, 'Reply');
      expect(darwinButton(deny).placeholder, isNull);
    });
  });
}
