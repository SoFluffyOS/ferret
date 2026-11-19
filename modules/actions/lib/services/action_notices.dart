import 'dart:async';

import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/services/actions_host.dart';
import 'package:actions/services/leave_lock.dart';
import 'package:feature_kit/feature_kit.dart';

/// The system notices on the computer: the question with its three
/// answers, and "Pixel 7 is restarting this Mac · Cancel" while the
/// countdown runs, so both reach the owner with Ferret out of sight. Also
/// "Locking this Mac: Pixel 7 left · Cancel" before a lock.
class ActionNotices {
  ActionNotices({
    required this.host,
    this.leaveLock,
    required this.notifier,
    required this.l10n,
    required this.reveal,
    ComputerKind? computer,
  }) : computer = computer ?? ComputerKind.here;

  static const consentNotice = 'actions.consent';
  static const countdownNotice = 'actions.countdown';
  static const leaveNotice = 'actions.leave';

  static const allowOnceAction = 'allow_once';
  static const alwaysAction = 'always';
  static const denyAction = 'deny';
  static const cancelAction = 'cancel';

  final ActionsHost host;
  final LeaveLock? leaveLock;
  final LocalNotifier notifier;
  final ActionsLocalizations l10n;
  final Future<void> Function() reveal;
  final ComputerKind computer;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  DateTime? _consentShownFor;
  DateTime? _countdownShownFor;
  DateTime? _leaveShownFor;

  static List<NoticeCategory> categories(ActionsLocalizations l10n) => [
    NoticeCategory(
      id: consentNotice,
      actions: [
        NoticeAction(id: alwaysAction, label: l10n.allowAlways),
        NoticeAction(id: allowOnceAction, label: l10n.allowOnce),
        NoticeAction(id: denyAction, label: l10n.dontAllow),
      ],
    ),
    NoticeCategory(
      id: countdownNotice,
      actions: [NoticeAction(id: cancelAction, label: l10n.cancel)],
    ),
    NoticeCategory(
      id: leaveNotice,
      actions: [NoticeAction(id: cancelAction, label: l10n.cancel)],
    ),
  ];

  void start() {
    _subscriptions
      ..add(host.changes.listen((_) => unawaited(_sync())))
      ..addAll([
        if (leaveLock case final leaveLock?)
          leaveLock.changes.listen((_) => unawaited(_syncLeave())),
      ])
      ..add(
        notifier.responses
            .where((response) => response.noticeId.startsWith('actions.'))
            .listen((response) => unawaited(_onResponse(response))),
      );
    unawaited(_sync());
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  Future<void> _sync() async {
    await _syncConsent();
    await _syncCountdown();
    await _syncLeave();
  }

  Future<void> _syncConsent() async {
    final pending = host.pending;
    if (pending == null) {
      if (_consentShownFor == null) {
        return;
      }

      _consentShownFor = null;
      await notifier.cancel(consentNotice);
      return;
    }

    if (_consentShownFor == pending.askedAt) {
      return;
    }

    _consentShownFor = pending.askedAt;
    await notifier.show(
      LocalNotice(
        id: consentNotice,
        channel: .incoming,
        title: l10n.consentTitleOf(pending, computer),
        body: l10n.consentNoticeBodyOf(pending),
        category: consentNotice,
      ),
    );
  }

  Future<void> _syncCountdown() async {
    final countdown = host.countdown;
    if (countdown == null) {
      if (_countdownShownFor == null) {
        return;
      }

      _countdownShownFor = null;
      await notifier.cancel(countdownNotice);
      return;
    }

    if (_countdownShownFor == countdown.startedAt) {
      return;
    }

    _countdownShownFor = countdown.startedAt;
    await notifier.show(
      LocalNotice(
        id: countdownNotice,
        channel: .incoming,
        title: l10n.countdownNoticeTitleOf(countdown, computer),
        body: l10n.countdownNoticeBody,
        category: countdownNotice,
      ),
    );
  }

  Future<void> _syncLeave() async {
    final countdown = leaveLock?.countdown;
    if (countdown == null) {
      if (_leaveShownFor == null) {
        return;
      }

      _leaveShownFor = null;
      await notifier.cancel(leaveNotice);
      return;
    }

    if (_leaveShownFor == countdown.startedAt) {
      return;
    }

    _leaveShownFor = countdown.startedAt;
    await notifier.show(
      LocalNotice(
        id: leaveNotice,
        channel: .incoming,
        title: l10n.leaveNoticeTitle(computer.name, countdown.deviceName),
        body: l10n.leaveNoticeBody,
        category: leaveNotice,
      ),
    );
  }

  Future<void> _onResponse(NoticeResponse response) async {
    switch ((response.noticeId, response.actionId)) {
      case (consentNotice, alwaysAction):
        await host.answer(.always);
      case (consentNotice, allowOnceAction):
        await host.answer(.allowOnce);
      case (consentNotice, denyAction):
        await host.answer(.deny);
      case (countdownNotice, cancelAction):
        host.cancelCountdown();
      case (leaveNotice, cancelAction):
        leaveLock?.cancel();
      default:
        await reveal();
    }
  }
}
