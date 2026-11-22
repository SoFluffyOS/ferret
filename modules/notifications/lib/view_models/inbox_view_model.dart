import 'dart:async';
import 'dart:math';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/l10n/generated/notifications_localizations.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/services/services.dart';

/// The phones' notifications on a computer: shows each one as a system
/// notice grouped per phone, keeps the recent ones for Activity and the full list, and
/// sends replies and dismissals back.
class InboxViewModel extends ChangeNotifier {
  InboxViewModel({
    required MirrorControl feature,
    required LocalNotifier notifier,
    required String Function(String deviceId) deviceName,
    required NotificationsLocalizations Function() strings,
    void Function(String deviceId)? onOpen,
  }) : _feature = feature,
       _notifier = notifier,
       _deviceName = deviceName,
       _strings = strings,
       _onOpen = onOpen {
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

  /// How many notifications the inbox keeps per phone.
  static const keptPerDevice = 50;

  final MirrorControl _feature;
  final LocalNotifier _notifier;
  final String Function(String deviceId) _deviceName;
  final NotificationsLocalizations Function() _strings;
  final void Function(String deviceId)? _onOpen;

  /// Notices one app may show per minute.
  final NoticeBudget _appBudget = NoticeBudget(limit: 3);

  /// Notices one phone may show per minute, all apps together.
  final NoticeBudget _phoneBudget = NoticeBudget(limit: 6);
  final List<StreamSubscription<Object?>> _subscriptions = [];

  final Map<String, List<MirroredNotification>> _byDevice = {};
  final Map<String, MirroredNotification> _byNotice = {};
  final Set<String> _catchUpNotices = {};

  /// What each phone kept quiet past its [NoticeBudget], by device id.
  final Map<String, _KeptQuiet> _keptQuiet = {};

  /// A quiet notice older than this starts again with one app.
  static const _quietResets = Duration(minutes: 10);

  /// Apps the quiet notice names; the rest are counted.
  static const _quietAppsNamed = 3;

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

    final otherIds = [
      ..._catchUpNotices,
      for (final deviceId in _keptQuiet.keys) _quietNoticeId(deviceId),
    ];
    _catchUpNotices.clear();
    _keptQuiet.clear();
    for (final noticeId in [...noticeIds, ...otherIds]) {
      await _notifier.cancel(noticeId);
    }
  }

  /// Drops what came from devices no longer paired, here and in the
  /// notification center: a removed phone's messages don't stay behind.
  Future<void> keepOnly(Set<String> pairedIds) async {
    final gone = [
      for (final deviceId in _byDevice.keys)
        if (!pairedIds.contains(deviceId)) deviceId,
    ];
    if (gone.isEmpty) {
      return;
    }

    final noticeIds = [
      for (final deviceId in gone)
        for (final item in _byDevice.remove(deviceId)!)
          _noticeId(deviceId, item.key),
    ];
    _byNotice.removeWhere((noticeId, _) => noticeIds.contains(noticeId));
    _appBudget.forget(
      (app) => gone.any((deviceId) => app.startsWith('$deviceId/')),
    );
    _phoneBudget.forget(gone.contains);
    for (final deviceId in gone) {
      if (_keptQuiet.remove(deviceId) != null) {
        noticeIds.add(_quietNoticeId(deviceId));
      }
    }

    notifyListeners();
    for (final noticeId in noticeIds) {
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

  void _onPosted(MirroredNotification posted) {
    final notification = switch (posted.textHidden) {
      true => posted.withText(_strings().codeHidden),
      false => posted,
    };
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

    if (!posted.textHidden && !_spendBudget(notification)) {
      _keepQuiet(notification);
      return;
    }

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
          private: PrivateContent(
            deviceId,
            cover: _strings().privateCover(_deviceName(deviceId)),
          ),
        ),
      ),
    );
  }

  /// Whether [notification] fits its app's and its phone's budget; spends
  /// both when it does. A one-time code always shows: it can't wait.
  bool _spendBudget(MirroredNotification notification) {
    final deviceId = notification.deviceId;
    final app = '$deviceId/${notification.appPackage}';
    final at = notification.postedAt;
    if (!_appBudget.allows(app, at) || !_phoneBudget.allows(deviceId, at)) {
      return false;
    }

    _appBudget.spend(app, at);
    _phoneBudget.spend(deviceId, at);
    return true;
  }

  /// Names [notification]'s app on its phone's one quiet notice. The
  /// notice shows again, without a sound, only when another app joins it.
  void _keepQuiet(MirroredNotification notification) {
    final deviceId = notification.deviceId;
    final at = notification.postedAt;
    final quiet = switch (_keptQuiet[deviceId]) {
      final kept? when at.difference(kept.lastAt) < _quietResets => kept,
      _ => _keptQuiet[deviceId] = _KeptQuiet(),
    };
    quiet.lastAt = at;
    if (!quiet.apps.add(notification.appName)) {
      return;
    }

    final strings = _strings();
    unawaited(
      _notifier.show(
        LocalNotice(
          id: _quietNoticeId(deviceId),
          channel: .incoming,
          title: _deviceName(deviceId),
          body: strings.keptQuiet(
            ListText.join(
              quiet.apps.take(_quietAppsNamed),
              localeName: strings.localeName,
            ),
            max(0, quiet.apps.length - _quietAppsNamed),
          ),
          groupKey: _groupKey(deviceId),
          silent: true,
          private: PrivateContent(
            deviceId,
            cover: strings.privateCover(_deviceName(deviceId)),
          ),
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
        ListText.join(event.missedAppNames, localeName: strings.localeName),
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
    final quietDevice = _keptQuiet.keys
        .where((deviceId) => _quietNoticeId(deviceId) == response.noticeId)
        .firstOrNull;
    if (quietDevice != null) {
      _keptQuiet.remove(quietDevice);
      _onOpen?.call(quietDevice);
      return;
    }

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

  /// Sends [text] as the answer to [notification] on its phone. False when
  /// the phone is gone or the notification no longer takes a reply.
  Future<bool> reply(MirroredNotification notification, String text) async {
    final action = notification.replyAction;
    if (action == null || text.trim().isEmpty) {
      return false;
    }

    return _feature.invokeAction(
      notification.deviceId,
      notification.key,
      action.id,
      replyText: text,
    );
  }

  Future<void> _reply(MirroredNotification notification, String text) async {
    if (text.trim().isEmpty || await reply(notification, text)) {
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
    while (items.length > keptPerDevice) {
      final oldest = items.removeLast();
      final noticeId = _noticeId(oldest.deviceId, oldest.key);
      _byNotice.remove(noticeId);
      unawaited(_notifier.cancel(noticeId));
    }
  }

  static String _noticeId(String deviceId, String key) =>
      '$_noticePrefix$deviceId/$key';

  static String _groupKey(String deviceId) => '$_noticePrefix$deviceId';

  static String _quietNoticeId(String deviceId) =>
      '$_noticePrefix$deviceId/quiet';
}

class _KeptQuiet {
  /// App names in the order they went quiet.
  final Set<String> apps = {};
  DateTime lastAt = DateTime.fromMillisecondsSinceEpoch(0);
}
