import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:messages/ui/ui.dart';
import 'package:protocol/messages.dart';

import 'support/fakes.dart';

void main() {
  late FakeSmsSource source;
  late PhoneAndComputer devices;
  late List<(String, int)> opened;

  final l10n = lookupMessagesLocalizations(const Locale('en'));

  List<ActivityItem> activity({bool paired = true}) => messagesActivity(
    l10n: l10n,
    library: devices.library,
    deviceName: (_) => 'Pixel',
    isPaired: (_) => paired,
    onOpen: (deviceId, threadId) => opened.add((deviceId, threadId)),
  );

  Future<void> start(List<Conversation> conversations) async {
    source = FakeSmsSource();
    conversations.forEach(source.addConversation);
    devices = await PhoneAndComputer.start(source: source);
    await devices.connect();
  }

  setUp(() => opened = []);

  tearDown(() => devices.stop());

  test('an unread text names who wrote and the phone it is on', () async {
    await start([conversationOf(1, lastDateMs: 1000, unread: 2)]);

    final line = activity().single;

    expect(line.id, 'messages.${PhoneAndComputer.phoneId}/1');
    expect(line.title, 'Alex · Pixel');
    expect(line.detail, 'Hi');
    expect(line.at, DateTime.fromMillisecondsSinceEpoch(1000));
    expect(line.pinned, isFalse);
    expect(line.actions.single.label, 'Reply');
  });

  test('Reply and a tap open that conversation', () async {
    await start([conversationOf(7, lastDateMs: 1000, unread: 1)]);

    final line = activity().single;
    line.actions.single.onPressed();
    line.onTap?.call();

    expect(opened, [
      (PhoneAndComputer.phoneId, 7),
      (PhoneAndComputer.phoneId, 7),
    ]);
  });

  test('read conversations leave no line', () async {
    await start([conversationOf(1, lastDateMs: 1000)]);

    expect(activity(), isEmpty);
  });

  test('a text with only a picture says so', () async {
    await start([conversationOf(1, lastDateMs: 1000, unread: 1, snippet: '')]);

    expect(activity().single.detail, 'Attachment');
  });

  test('at most three, the newest first', () async {
    await start([
      for (final threadId in [1, 2, 3, 4])
        conversationOf(
          threadId,
          lastDateMs: threadId * 1000,
          unread: 1,
          name: 'Friend $threadId',
          address: '+1555000$threadId',
        ),
    ]);

    expect(activity().map((line) => line.title), [
      'Friend 4 · Pixel',
      'Friend 3 · Pixel',
      'Friend 2 · Pixel',
    ]);
  });

  test('a phone that is no longer paired leaves no line', () async {
    await start([conversationOf(1, lastDateMs: 1000, unread: 1)]);

    expect(activity(paired: false), isEmpty);
  });
}
