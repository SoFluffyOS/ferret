import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/ui/widgets/widgets.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('a received sign-in code has Copy code, which copies the '
      'digits', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );

    await tester.pumpWidget(
      testApp(
        MessageBubble(
          message: messageOf(
            'sms:1',
            threadId: 1,
            dateMs: 0,
            body: 'Your verification code is 482-913',
          ),
          time: '9:41',
        ),
      ),
    );

    await tester.tap(find.text('Copy code'));
    await tester.pump();

    expect(copied, ['482913']);
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copy code'), findsOneWidget);
  });

  testWidgets('ordinary texts and my own have no Copy code', (tester) async {
    await tester.pumpWidget(
      testApp(
        MessageBubble(
          message: messageOf(
            'sms:2',
            threadId: 1,
            dateMs: 0,
            body: 'My code is 4821, see you',
            kind: .MESSAGE_KIND_SENT,
          ),
          time: '9:41',
        ),
      ),
    );

    expect(find.text('Copy code'), findsNothing);
  });
}
