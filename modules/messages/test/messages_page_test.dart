import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/ui/ui.dart';
import 'package:protocol/messages.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  const phoneId = PhoneAndComputer.phoneId;
  late FakeSmsSource source;
  late PhoneAndComputer devices;
  late int now;

  setUp(() {
    now = DateTime.now().millisecondsSinceEpoch;
    source = FakeSmsSource()
      ..addConversation(
        conversationOf(
          1,
          lastDateMs: now - 1000,
          name: 'Alex',
          snippet: 'See you',
          unread: 2,
        ),
      )
      ..addConversation(
        conversationOf(
          2,
          lastDateMs: now - 2000,
          participants: [
            Participant(address: '+15550002', name: 'Bo'),
            Participant(address: '+15550003', name: 'Cy'),
          ],
          snippet: 'Lunch?',
        ),
      )
      ..addMessage(
        messageOf('sms:1', threadId: 1, dateMs: now - 5000, body: 'Hi there'),
      )
      ..addMessage(
        messageOf(
          'sms:2',
          threadId: 1,
          dateMs: now - 4000,
          body: 'Hello!',
          kind: .MESSAGE_KIND_SENT,
        ),
      )
      ..addMessage(
        messageOf(
          'mms:3',
          threadId: 1,
          dateMs: now - 1000,
          body: 'See you',
          attachments: [
            Attachment(partId: '7', mime: 'image/png', thumbnailJpeg: tinyPng),
          ],
        ),
      )
      ..addMessage(
        messageOf(
          'sms:4',
          threadId: 2,
          dateMs: now - 2000,
          body: 'Lunch?',
          sender: '+15550003',
        ),
      );
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    bool connect = true,
    int? threadId,
    Size size = const Size(1000, 800),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      devices = await PhoneAndComputer.start(source: source);
      if (connect) {
        await devices.connect();
      }
    });

    await tester.pumpWidget(
      testApp(
        MessagesPage(
          library: devices.library,
          deviceId: phoneId,
          phoneName: 'Pixel',
          initialThreadId: threadId,
        ),
        scroll: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.runAsync(devices.stop);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('lists conversations with names, snippets and unread', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Bo, Cy'), findsOneWidget);
    expect(find.text('Lunch?'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Pick a conversation'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a thread shows bubbles, a day, a picture and marks read', (
    tester,
  ) async {
    await pumpPage(tester, threadId: 1);

    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(source.markedRead, [1]);
    await finish(tester);
  });

  testWidgets('sending shows the reply pending, then the sent text', (
    tester,
  ) async {
    await pumpPage(tester, threadId: 1);

    await tester.enterText(find.byType(EditableText), 'On my way');
    source.addMessage(
      messageOf(
        'sms:5',
        threadId: 1,
        dateMs: now,
        body: 'On my way',
        kind: .MESSAGE_KIND_SENT,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(source.sent.single.text, 'On my way');
    expect(find.text('On my way'), findsOneWidget);
    expect(find.text('Sending…'), findsNothing);
    await finish(tester);
  });

  testWidgets('a failed reply says why and can be retried', (tester) async {
    await pumpPage(tester, threadId: 1);
    source.sendResult = SendResult(failure: .SEND_FAILURE_NO_SERVICE);

    await tester.enterText(find.byType(EditableText), 'Anyone?');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Not sent. Pixel has no signal.'), findsOneWidget);

    source.sendResult = SendResult(ok: true);
    await tester.tap(find.text('Send again'));
    await tester.pumpAndSettle();

    expect(source.sent, hasLength(2));
    expect(find.textContaining('Not sent.'), findsNothing);
    await finish(tester);
  });

  testWidgets('group conversations explain why replies stay on the phone', (
    tester,
  ) async {
    await pumpPage(tester, threadId: 2);

    expect(find.textContaining('Group texts need MMS'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Cy'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('offline shows saved texts and says when replying works', (
    tester,
  ) async {
    await pumpPage(tester, threadId: 1);
    await tester.runAsync(devices.disconnect);
    await tester.pumpAndSettle();

    expect(find.textContaining('Pixel is offline.'), findsNothing);
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('Reply once Pixel is back.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Messages off on the phone is explained with a retry', (
    tester,
  ) async {
    await tester.runAsync(() async {});
    source.canRead = false;
    await pumpPage(tester);

    expect(
      find.text(
        "Ferret on Pixel can't read texts yet. On Pixel: open Ferret and allow SMS.",
      ),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('narrow windows show the list, then one thread with back', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(400, 800));

    expect(find.text('Pick a conversation'), findsNothing);
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(find.text('Hi there'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('Bo, Cy'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('an empty phone says there is nothing yet', (tester) async {
    source = FakeSmsSource();
    await pumpPage(tester);

    expect(find.text('No conversations yet.'), findsOneWidget);
    await finish(tester);
  });
}
