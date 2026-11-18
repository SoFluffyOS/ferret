import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:iphone/feature/iphone_feature.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/models/models.dart';

/// Shows the iPhone's notifications as notices on this computer, grouped by
/// app, with the iPhone's own actions. A burst is shown quietly, and what
/// goes away on the iPhone goes away here.
class IphoneNotices {
  IphoneNotices({
    required this.feature,
    required this.notifier,
    required this.l10n,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const clearCategory = 'iphone.clear';
  static const callCategory = 'iphone.call';
  static const callBackCategory = 'iphone.call_back';
  static const acceptCategory = 'iphone.accept';
  static const acceptOrClearCategory = 'iphone.accept_or_clear';
  static const positiveAction = 'positive';
  static const negativeAction = 'negative';
  static const failedNoticeId = 'iphone.action-failed';

  static const _noticePrefix = 'iphone.n.';

  /// More notices than this within [_burstWindow] arrive without a sound.
  static const _burstSize = 4;
  static const _burstWindow = Duration(seconds: 10);

  final IphoneFeature feature;
  final LocalNotifier notifier;
  final IphoneLocalizations l10n;
  final DateTime Function() _clock;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<DateTime> _recent = [];

  static List<NoticeCategory> categories(IphoneLocalizations l10n) {
    final clear = NoticeAction(id: negativeAction, label: l10n.actionClear);
    final accept = NoticeAction(id: positiveAction, label: l10n.actionAccept);

    return [
      NoticeCategory(id: clearCategory, actions: [clear]),
      NoticeCategory(
        id: callCategory,
        actions: [
          NoticeAction(id: positiveAction, label: l10n.actionAnswer),
          NoticeAction(id: negativeAction, label: l10n.actionDecline),
        ],
      ),
      NoticeCategory(
        id: callBackCategory,
        actions: [
          NoticeAction(id: positiveAction, label: l10n.actionCallBack),
          clear,
        ],
      ),
      NoticeCategory(id: acceptCategory, actions: [accept]),
      NoticeCategory(id: acceptOrClearCategory, actions: [accept, clear]),
    ];
  }

  static String noticeIdOf(int uid) => '$_noticePrefix$uid';

  void start() {
    _subscriptions
      ..add(feature.notifications.listen((event) => unawaited(_onEvent(event))))
      ..add(
        notifier.responses
            .where((response) => response.noticeId.startsWith(_noticePrefix))
            .listen((response) => unawaited(_onResponse(response))),
      );
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    _subscriptions.clear();
  }

  Future<void> _onEvent(FeedEvent event) => switch (event) {
    FeedShown(:final notification) => _show(notification),
    FeedRemoved(:final uid) => notifier.cancel(noticeIdOf(uid)),
  };

  Future<void> _show(IphoneNotification notification) async {
    final quiet = notification.isSilent || notification.isUpdate || _isBurst();
    final (title, body) = _textOf(notification);

    await notifier.show(
      LocalNotice(
        id: noticeIdOf(notification.uid),
        channel: .incoming,
        title: title,
        body: body,
        category: _categoryOf(notification),
        groupKey: 'iphone.${notification.appId}',
        silent: quiet,
      ),
    );
  }

  (String, String) _textOf(IphoneNotification notification) {
    final app = switch (notification.appName.isEmpty) {
      true => l10n.noticeFromIphone,
      false => notification.appName,
    };
    if (feature.settings.hidePreviews) {
      return (app, l10n.noticeHidden);
    }

    final title = notification.title;
    final heading = switch (title.isEmpty || title == app) {
      true => app,
      false => l10n.noticeTitle(app, title),
    };
    final body = [
      notification.subtitle,
      notification.message,
    ].where((line) => line.isNotEmpty).join('\n');

    return (heading, body);
  }

  String? _categoryOf(IphoneNotification notification) {
    final positive = notification.hasPositiveAction;
    final negative = notification.hasNegativeAction;
    if (!positive && !negative) {
      return null;
    }

    if (!positive) {
      return clearCategory;
    }

    if (!negative) {
      return acceptCategory;
    }

    return switch (notification.category) {
      .incomingCall => callCategory,
      .missedCall || .voicemail => callBackCategory,
      _ => acceptOrClearCategory,
    };
  }

  bool _isBurst() {
    final now = _clock();
    _recent
      ..removeWhere((shownAt) => now.difference(shownAt) > _burstWindow)
      ..add(now);

    return _recent.length > _burstSize;
  }

  Future<void> _onResponse(NoticeResponse response) async {
    final uid = int.tryParse(response.noticeId.substring(_noticePrefix.length));
    final action = switch (response.actionId) {
      positiveAction => AncsAction.positive,
      negativeAction => AncsAction.negative,
      _ => null,
    };
    if (uid == null || action == null) {
      return;
    }

    final done = await feature.perform(uid, action);
    if (done) {
      await notifier.cancel(response.noticeId);
      return;
    }

    final deviceName = feature.link.deviceName;
    final device = switch (deviceName.isEmpty) {
      true => l10n.noticeFromIphone,
      false => deviceName,
    };
    await notifier.show(
      LocalNotice(
        id: failedNoticeId,
        channel: .problems,
        title: l10n.actionFailedTitle(device),
        body: l10n.actionFailedBody(device),
      ),
    );
  }
}
