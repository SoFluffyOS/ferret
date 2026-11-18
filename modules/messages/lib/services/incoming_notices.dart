import 'dart:async';
import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/message_library.dart';
import 'package:protocol/messages.dart';

/// Shows a notice with Reply for each conversation that gets a new text
/// while it isn't on screen here. One notice per conversation, updated as
/// texts arrive, so a busy chat never floods.
class IncomingNotices {
  IncomingNotices({
    required MessageLibrary library,
    required LocalNotifier notifier,
    required bool Function() enabled,
    required bool Function(String deviceId, int threadId) isShowing,
    required MessagesLocalizations Function() strings,
    required String Function(String deviceId) deviceName,
    required void Function(String deviceId, int threadId) onOpen,
  }) : _library = library,
       _notifier = notifier,
       _enabled = enabled,
       _isShowing = isShowing,
       _strings = strings,
       _deviceName = deviceName,
       _onOpen = onOpen;

  /// Notices with Reply and Mark as read.
  static const messageCategory = 'messages.message';

  /// Group conversations: SMS can't answer them, so only Mark as read.
  static const groupCategory = 'messages.group';

  static const replyActionId = 'reply';
  static const markReadActionId = 'mark_read';

  static const _prefix = 'messages/';

  final MessageLibrary _library;
  final LocalNotifier _notifier;
  final bool Function() _enabled;
  final bool Function(String deviceId, int threadId) _isShowing;
  final MessagesLocalizations Function() _strings;
  final String Function(String deviceId) _deviceName;
  final void Function(String deviceId, int threadId) _onOpen;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Texts shown per notice since it was last cleared.
  final Map<String, int> _counts = {};

  static List<NoticeCategory> categories(MessagesLocalizations strings) => [
    NoticeCategory(
      id: messageCategory,
      actions: [
        NoticeAction(
          id: replyActionId,
          label: strings.replyAction,
          isReply: true,
        ),
        NoticeAction(id: markReadActionId, label: strings.markReadAction),
      ],
    ),
    NoticeCategory(
      id: groupCategory,
      actions: [
        NoticeAction(id: markReadActionId, label: strings.markReadAction),
      ],
    ),
  ];

  static String noticeIdFor(String deviceId, int threadId) =>
      '$_prefix$deviceId/$threadId';

  void start() {
    _subscriptions
      ..add(
        _library.events.listen((event) {
          if (event case final IncomingMessage incoming) {
            unawaited(_onIncoming(incoming));
          }
        }),
      )
      ..add(
        _notifier.responses
            .where((response) => response.noticeId.startsWith(_prefix))
            .listen((response) => unawaited(_onResponse(response))),
      );
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  /// Clears the notice of a conversation, such as when it is opened here.
  Future<void> clear(String deviceId, int threadId) async {
    final noticeId = noticeIdFor(deviceId, threadId);
    if (_counts.remove(noticeId) == null) {
      return;
    }

    await _notifier.cancel(noticeId);
  }

  Future<void> _onIncoming(IncomingMessage event) async {
    final deviceId = event.deviceId;
    final message = event.message;
    final threadId = message.threadId.toInt();
    if (!_enabled() || _isShowing(deviceId, threadId)) {
      return;
    }

    final noticeId = noticeIdFor(deviceId, threadId);
    final count = (_counts[noticeId] ?? 0) + 1;
    _counts[noticeId] = count;

    final strings = _strings();
    final conversation = event.conversation;
    final isGroup = conversation?.isGroup ?? false;
    final name = switch (conversation) {
      final Conversation known when known.title.isNotEmpty => known.title,
      _ => message.senderAddress,
    };
    final text = strings.preview(message);
    final body = switch (isGroup) {
      true => strings.noticeGroupBody(
        conversation?.nameFor(message.senderAddress) ?? message.senderAddress,
        text,
      ),
      false => text,
    };

    await _notifier.show(
      LocalNotice(
        id: noticeId,
        channel: .incoming,
        title: switch (count > 1) {
          true => strings.noticeTitleCount(name, count),
          false => name,
        },
        body: body,
        category: switch (isGroup) {
          true => groupCategory,
          false => messageCategory,
        },
        groupKey: '$_prefix$deviceId',
        image: _avatarOf(conversation, message.senderAddress),
      ),
    );
  }

  Future<void> _onResponse(NoticeResponse response) async {
    final target = _parse(response.noticeId);
    if (target == null) {
      return;
    }

    final (deviceId, threadId) = target;
    switch (response.actionId) {
      case replyActionId:
        await _reply(deviceId, threadId, response.replyText ?? '');
      case markReadActionId:
        await clear(deviceId, threadId);
        await _library.markRead(deviceId, threadId);
      case null:
        await clear(deviceId, threadId);
        _onOpen(deviceId, threadId);
    }
  }

  Future<void> _reply(String deviceId, int threadId, String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    await clear(deviceId, threadId);
    final outcome = await _library.send(deviceId, threadId, text);
    if (outcome == .sent) {
      await _library.markRead(deviceId, threadId);
      return;
    }

    final strings = _strings();
    await _notifier.show(
      LocalNotice(
        id: '$_prefix$deviceId/reply-failed',
        channel: .problems,
        title: strings.replyFailedTitle,
        body: '${_deviceName(deviceId)}: ${strings.outcomeText(outcome)}',
        groupKey: '$_prefix$deviceId',
      ),
    );
  }

  static (String, int)? _parse(String noticeId) {
    final parts = noticeId.substring(_prefix.length).split('/');
    if (parts.length != 2) {
      return null;
    }

    final threadId = int.tryParse(parts.last);
    if (threadId == null) {
      return null;
    }

    return (parts.first, threadId);
  }

  static Uint8List? _avatarOf(Conversation? conversation, String address) {
    final avatar = conversation?.participantFor(address)?.avatarJpeg;
    if (avatar == null || avatar.isEmpty) {
      return null;
    }

    return Uint8List.fromList(avatar);
  }
}
