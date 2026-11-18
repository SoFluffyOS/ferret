import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/control_host.dart';

/// The system notices on the controlled computer: the consent question
/// with its three answers, the persistent "Controlled by Pixel · Stop"
/// while it lasts, and a missing permission with a fix.
class ControlNotices {
  ControlNotices({
    required this.host,
    required this.notifier,
    required this.l10n,
    required this.reveal,
  });

  static const consentNotice = 'remote_input.consent';
  static const activeNotice = 'remote_input.active';
  static const permissionNotice = 'remote_input.permission';

  static const allowOnceAction = 'allow_once';
  static const alwaysAction = 'always';
  static const denyAction = 'deny';
  static const stopAction = 'stop';
  static const openSettingsAction = 'open_settings';

  final ControlHost host;
  final LocalNotifier notifier;
  final RemoteInputLocalizations l10n;
  final Future<void> Function() reveal;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  DateTime? _consentShownFor;
  DateTime? _activeShownFor;
  DateTime? _permissionShownFor;

  static List<NoticeCategory> categories(RemoteInputLocalizations l10n) => [
    NoticeCategory(
      id: consentNotice,
      actions: [
        NoticeAction(id: alwaysAction, label: l10n.allowAlways),
        NoticeAction(id: allowOnceAction, label: l10n.allowOnce),
        NoticeAction(id: denyAction, label: l10n.dontAllow),
      ],
    ),
    NoticeCategory(
      id: activeNotice,
      actions: [NoticeAction(id: stopAction, label: l10n.stop)],
    ),
    NoticeCategory(
      id: permissionNotice,
      actions: [NoticeAction(id: openSettingsAction, label: l10n.openSettings)],
    ),
  ];

  void start() {
    _subscriptions
      ..add(host.changes.listen((_) => unawaited(_sync())))
      ..add(
        notifier.responses
            .where((response) => response.noticeId.startsWith('remote_input.'))
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
    await _syncActive();
    await _syncPermission();
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
        title: l10n.consentTitle(pending.deviceName),
        body: l10n.consentBody(pending.deviceName),
        category: consentNotice,
      ),
    );
  }

  Future<void> _syncActive() async {
    final active = host.active;
    if (active == null) {
      if (_activeShownFor == null) {
        return;
      }

      _activeShownFor = null;
      await notifier.cancel(activeNotice);
      return;
    }

    if (_activeShownFor == active.startedAt) {
      return;
    }

    _activeShownFor = active.startedAt;
    await notifier.show(
      LocalNotice(
        id: activeNotice,
        channel: .incoming,
        title: l10n.controlledBy(active.deviceName),
        body: l10n.activeNoticeBody,
        category: activeNotice,
        silent: true,
        ongoing: true,
      ),
    );
  }

  Future<void> _syncPermission() async {
    final ask = host.permissionAsk;
    if (ask == null) {
      if (_permissionShownFor == null) {
        return;
      }

      _permissionShownFor = null;
      await notifier.cancel(permissionNotice);
      return;
    }

    if (_permissionShownFor == ask.askedAt) {
      return;
    }

    _permissionShownFor = ask.askedAt;
    await notifier.show(
      LocalNotice(
        id: permissionNotice,
        channel: .problems,
        title: l10n.permissionTitle(ask.deviceName),
        body: l10n.permissionBody(ask.deviceName),
        category: permissionNotice,
      ),
    );
  }

  Future<void> _onResponse(NoticeResponse response) async {
    switch ((response.noticeId, response.actionId)) {
      case (consentNotice, alwaysAction):
        await host.answer(ConsentChoice.always);
      case (consentNotice, allowOnceAction):
        await host.answer(ConsentChoice.allowOnce);
      case (consentNotice, denyAction):
        await host.answer(ConsentChoice.deny);
      case (activeNotice, stopAction):
        await host.stop();
      case (permissionNotice, openSettingsAction):
        await host.requestAccess();
      default:
        await reveal();
    }
  }
}
