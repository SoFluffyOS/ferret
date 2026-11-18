import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/l10n/generated/notifications_localizations.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/services/services.dart';

/// The phones' notifications on a computer: shows each one as a system
/// notice grouped per phone, keeps the recent ones for the home card, and
/// sends replies and dismissals back.
class InboxViewModel extends ChangeNotifier {
  InboxViewModel({
    required MirrorControl feature,
    required LocalNotifier notifier,
    required String Function(String deviceId) deviceName,
    required NotificationsLocalizations Function() strings,
  }) : _feature = feature,
       _notifier = notifier,
       _deviceName = deviceName,
       _strings = strings {
    _subscriptions
      ..add(feature.mirrorEvents.listen(_onEvent))
      ..add(
        notifier.responses
            .where((response) => response.noticeId.startsWith(_noticePrefix))
            .listen((response) => unawaited(_onResponse(response))),
      );
  }

  /// Notices with Reply and Dismiss.
  static const messageCategory = '${NotificationsFeature.featureId}.message';

  /// Notices with only Dismiss.
  static const alertCategory = '${NotificationsFeature.featureId}.alert';

  static const replyActionId = 'reply';
  static const dismissActionId = 'dismiss';

  static const _noticePrefix = '${NotificationsFeature.featureId}/';
  static const _keptPerDevice = 50;

  final MirrorControl _feature;
  final LocalNotifier _notifier;
  final String Function(String deviceId) _deviceName;
  final NotificationsLocalizations Function() _strings;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  final Map<String, List<MirroredNotification>> _byDevice = {};
  final Map<String, MirroredNotification> _byNotice = {};
  final Set<String> _catchUpNotices = {};

  /// Recent notifications per phone, newest first.
  Map<String, List<MirroredNotification>> get byDevice => {
    for (final MapEntry(key: deviceId, value: items) in _byDevice.entries)
      if (items.isNotEmpty) deviceId: List.unmodifiable(items),
  };

  bool get isEmpty => _byDevice.values.every((items) => items.isEmpty);

  /// The name of [deviceId] as paired, even while it is offline.
  String deviceName(String deviceId) => _deviceName(deviceId);

  /// The notice actions the inbox needs, registered before the first notice.
  static List<NoticeCategory> categories(NotificationsLocalizations strings) =>
      [
        NoticeCategory(
          id: messageCategory,
          actions: [
            NoticeAction(
              id: replyActionId,
              label: strings.reply,
              isReply: true,
            ),
            NoticeAction(id: dismissActionId, label: strings.dismiss),
          ],
        ),
        NoticeCategory(
          id: alertCategory,
          actions: [NoticeAction(id: dismissActionId, label: strings.dismiss)],
        ),
      ];

  /// Dismisses [notification] here and on its phone.
  Future<void> dismiss(MirroredNotification notification) async {
    _forget(notification.deviceId, notification.key);
    notifyListeners();
    await _feature.dismiss(notification.deviceId, notification.key);
  }

  /// Clears this computer's list and notices. The phones keep theirs.
  Future<void> clearAll() async {
    final noticeIds = [..._byNotice.keys];
    _byNotice.clear();
    _byDevice.clear();
    notifyListeners();

    final catchUpIds = [..._catchUpNotices];
    _catchUpNotices.clear();
    for (final noticeId in [...noticeIds, ...catchUpIds]) {
      await _notifier.cancel(noticeId);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  void _onEvent(MirrorEvent event) {
    switch (event) {
      case MirrorPosted(:final notification):
        _onPosted(notification);
      case MirrorRemoved(:final deviceId, :final key):
        _onRemoved(deviceId, key);
      case MirrorCaughtUp():
        _onCaughtUp(event);
      case MirrorSettingsChanged() ||
          MirrorSettingsUnavailable() ||
          MirrorSourceGone():
        notifyListeners();
    }
  }

  void _onPosted(MirroredNotification notification) {
    final deviceId = notification.deviceId;
    final noticeId = _noticeId(deviceId, notification.key);
    final items = _byDevice.putIfAbsent(deviceId, () => []);
    final isUpdate = _byNotice.containsKey(noticeId);

    items
      ..removeWhere((item) => item.key == notification.key)
      ..insert(0, notification);
    _byNotice[noticeId] = notification;
    _trim(items);
    notifyListeners();

    final category = switch (notification.canReply) {
      true => messageCategory,
      false => alertCategory,
    };
    unawaited(
      _notifier.show(
        LocalNotice(
          id: noticeId,
          channel: .incoming,
          title: notification.heading,
          body: notification.text,
          category: category,
          groupKey: _groupKey(deviceId),
          image: notification.appIcon,
          silent: isUpdate,
        ),
      ),
    );
  }

  void _onRemoved(String deviceId, String key) {
    if (!_forget(deviceId, key)) {
      return;
    }

    notifyListeners();
  }

  void _onCaughtUp(MirrorCaughtUp event) {
    final deviceId = event.deviceId;
    final stale = [
      for (final item in _byDevice[deviceId] ?? const <MirroredNotification>[])
        if (!event.activeKeys.contains(item.key)) item.key,
    ];
    for (final key in stale) {
      _forget(deviceId, key);
    }

    if (stale.isNotEmpty) {
      notifyListeners();
    }

    if (event.missedCount == 0) {
      return;
    }

    final strings = _strings();
    final body = switch (event.missedAppNames.isEmpty) {
      true => strings.whileAway(event.missedCount),
      false => strings.whileAwayFrom(
        event.missedCount,
        event.missedAppNames.join(', '),
      ),
    };
    final noticeId = '$_noticePrefix$deviceId/catch-up';
    _catchUpNotices.add(noticeId);
    unawaited(
      _notifier.show(
        LocalNotice(
          id: noticeId,
          channel: .incoming,
          title: _deviceName(deviceId),
          body: body,
          groupKey: _groupKey(deviceId),
          silent: true,
        ),
      ),
    );
  }

  Future<void> _onResponse(NoticeResponse response) async {
    final notification = _byNotice[response.noticeId];
    if (notification == null) {
      return;
    }

    switch (response.actionId) {
      case dismissActionId:
        await dismiss(notification);
      case replyActionId:
        await _reply(notification, response.replyText ?? '');
    }
  }

  Future<void> _reply(MirroredNotification notification, String text) async {
    final action = notification.replyAction;
    if (action == null || text.trim().isEmpty) {
      return;
    }

    final sent = await _feature.invokeAction(
      notification.deviceId,
      notification.key,
      action.id,
      replyText: text,
    );
    if (sent) {
      return;
    }

    final strings = _strings();
    await _notifier.show(
      LocalNotice(
        id: '$_noticePrefix${notification.deviceId}/reply-failed',
        channel: .problems,
        title: strings.replyFailedTitle,
        body: strings.replyFailedBody(_deviceName(notification.deviceId)),
        groupKey: _groupKey(notification.deviceId),
      ),
    );
  }

  bool _forget(String deviceId, String key) {
    final noticeId = _noticeId(deviceId, key);
    final known = _byNotice.remove(noticeId) != null;
    _byDevice[deviceId]?.removeWhere((item) => item.key == key);
    unawaited(_notifier.cancel(noticeId));
    return known;
  }

  void _trim(List<MirroredNotification> items) {
    while (items.length > _keptPerDevice) {
      final oldest = items.removeLast();
      _byNotice.remove(_noticeId(oldest.deviceId, oldest.key));
    }
  }

  static String _noticeId(String deviceId, String key) =>
      '$_noticePrefix$deviceId/$key';

  static String _groupKey(String deviceId) => '$_noticePrefix$deviceId';
}
