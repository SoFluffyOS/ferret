// A phone's texts on a computer, for someone who texts all day: 500
// conversations, Vietnamese names, a group, a sign-in code and a picture.
// Rendered into temp/screens as `msgs_<name>_<size>_<mode>.png`. Run from
// apps/ferret:
//
//   flutter test test/screens/messages_screens_test.dart
@Tags(['screens'])
library;

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:protocol/messages.dart';

import 'screens_test.dart' show phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';
import 'window_screens_test.dart' show appFeatures, windowSizes;

void main() {
  setUpAll(loadScreenFonts);

  for (final size in [windowSizes.first, windowSizes[2]]) {
    for (final brightness in Brightness.values) {
      testWidgets('messages ${size.name} ${brightness.name}', (tester) async {
        setScreen(tester, size, brightness);
        mockPlugins(tester);
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final rig = await ScreenRig.create(
          tester,
          features: appFeatures(),
          tipsDone: true,
        );
        await rig.show(tester);

        final feature = MessagesFeature(source: _SampleSms());
        await rig.pairConnectedPhone(
          tester,
          phoneFeatures: [
            for (final ui in phoneFeatures())
              switch (ui.featureId) {
                MessagesFeature.featureId => MessagesFeatureUi.withFeature(
                  feature,
                ),
                _ => ui,
              },
          ],
        );
        await tester.runAsync(() async {
          await feature.settings.setEnabled(true);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await rig.settle(tester);
        await rig.tapText(tester, 'Messages');
        await rig.settle(tester, real: const Duration(seconds: 1));
        await rig.capture(tester, 'msgs_list', size, brightness);

        final search = find.byType(EditableText).first;
        await tester.enterText(search, 'nguyen');
        await rig.settle(tester);
        await rig.capture(tester, 'msgs_search', size, brightness);

        await tester.enterText(search, 'zzz');
        await rig.settle(tester);
        await rig.capture(tester, 'msgs_search_none', size, brightness);

        await tester.enterText(search, '');
        await rig.settle(tester);
        await rig.tapText(tester, 'VCB');
        await rig.settle(tester, real: const Duration(seconds: 1));
        await rig.capture(tester, 'msgs_code', size, brightness);
        await rig.dispose(tester);
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }
}

/// A phone with 500 conversations and every kind of text.
class _SampleSms implements SmsSource {
  _SampleSms() {
    const names = [
      'Nguyễn Thị Ánh',
      'Mẹ',
      'Trần Văn Bảo',
      'Lê Hoàng Minh',
      'Đặng Thu Hà',
      'Maya Okafor',
      'Phạm Ngọc Ước',
      'Nguyen Van Long',
    ];
    for (var index = 0; index < 500; index++) {
      final threadId = index + 1;
      final date = _now - index * 37 * 60000;
      final (participants, snippet) = switch (index) {
        0 => (
          [_person('VCB', '8149')],
          'Ma OTP cua ban la 482913. Het han sau 5 phut.',
        ),
        1 => (
          [
            _person('Bảo', '+84901000002'),
            _person('Hà', '+84901000003'),
            _person('Minh', '+84901000004'),
          ],
          'Hà: Tối nay ai đi ăn lẩu không? 🍲',
        ),
        _ => (
          [_person(names[index % names.length], '+8490${1000000 + index}')],
          'Tin nhắn số $index · see you soon 👋',
        ),
      };
      conversations[threadId] = Conversation(
        threadId: Int64(threadId),
        participants: participants,
        snippet: snippet,
        lastDateMs: Int64(date),
        unreadCount: index < 3 ? 1 : 0,
        isGroup: participants.length > 1,
      );
      threads[threadId] = [
        Message(
          id: 'sms:${threadId}a',
          threadId: Int64(threadId),
          senderAddress: participants.first.address,
          body: 'Xin chào!',
          dateMs: Int64(date - 600000),
          kind: .MESSAGE_KIND_INBOX,
          read: true,
        ),
        Message(
          id: 'sms:${threadId}b',
          threadId: Int64(threadId),
          senderAddress: participants.first.address,
          body: snippet,
          dateMs: Int64(date),
          kind: .MESSAGE_KIND_INBOX,
          read: index >= 3,
        ),
      ];
    }
  }

  static final _now = DateTime(2026, 11, 23, 9, 41).millisecondsSinceEpoch;

  final Map<int, Conversation> conversations = {};
  final Map<int, List<Message>> threads = {};

  static Participant _person(String name, String address) =>
      Participant(name: name, address: address);

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<SmsAccess> access() async => const SmsAccess(
    hasTelephony: true,
    canRead: true,
    canSend: true,
    canReadContacts: true,
  );

  @override
  Future<SmsAccess> requestAccess() => access();

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<ConversationPage> listConversations({
    int beforeDateMs = 0,
    required int limit,
  }) async {
    final matching =
        conversations.values
            .where(
              (conversation) =>
                  beforeDateMs == 0 ||
                  conversation.lastDateMs.toInt() < beforeDateMs,
            )
            .toList()
          ..sort((a, b) => b.lastDateMs.compareTo(a.lastDateMs));
    return ConversationPage(
      conversations: matching.take(limit),
      hasMore: matching.length > limit,
    );
  }

  @override
  Future<List<Conversation>> conversationsById(List<int> threadIds) async => [
    for (final threadId in threadIds) ?conversations[threadId],
  ];

  @override
  Future<MessagePage> listMessages(
    int threadId, {
    int beforeDateMs = 0,
    List<String> skipIds = const [],
    required int limit,
  }) async => MessagePage(
    threadId: Int64(threadId),
    messages: (threads[threadId] ?? const <Message>[]).reversed,
  );

  @override
  Future<List<Message>> recentMessages({
    required int sinceDateMs,
    required int limit,
  }) async => const [];

  @override
  Future<AttachmentData?> fetchAttachment(
    String messageId,
    String partId,
  ) async => null;

  @override
  Future<SendResult> send(SendText request) async => SendResult(ok: true);

  @override
  Future<bool> markRead(int threadId) async => false;

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}
}
