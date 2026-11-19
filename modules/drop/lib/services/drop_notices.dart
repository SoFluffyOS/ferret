import 'dart:async';

import 'package:drop/feature/drop_feature.dart';
import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:feature_kit/feature_kit.dart';

/// Shows Drop's notices on the transfers channel: progress while a transfer
/// runs, then one result. Progress updates are rate limited and silent.
class DropNotices {
  DropNotices({
    required this.feature,
    required this.notifier,
    required this.l10n,
    required this.onOpen,
    required this.onReveal,
    required this.onCopy,
    this.folderLabel,
    this.progressInterval = const Duration(seconds: 1),
  });

  static const progressCategory = 'drop.progress';
  static const filesCategory = 'drop.files';
  static const textCategory = 'drop.text';
  static const failedCategory = 'drop.failed';
  static const offerCategory = 'drop.offer';

  static const openAction = 'open';
  static const revealAction = 'reveal';
  static const copyAction = 'copy';
  static const retryAction = 'retry';
  static const cancelAction = 'cancel';
  static const acceptAction = 'accept';
  static const declineAction = 'decline';

  static const _prefix = 'drop.';

  final DropFeature feature;
  final LocalNotifier notifier;
  final DropLocalizations l10n;
  final Future<void> Function(Transfer transfer) onOpen;
  final Future<void> Function(Transfer transfer) onReveal;
  final Future<void> Function(String text) onCopy;

  /// Where received files land, as people know the folder, for "Saved to
  /// Downloads › Ferret". Null or empty says just "Saved".
  final String Function()? folderLabel;
  final Duration progressInterval;

  final Map<String, DateTime> _shown = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// The action sets Drop's notices use.
  static List<NoticeCategory> categories(DropLocalizations l10n) => [
    NoticeCategory(
      id: progressCategory,
      actions: [NoticeAction(id: cancelAction, label: l10n.actionCancel)],
    ),
    NoticeCategory(
      id: filesCategory,
      actions: [
        NoticeAction(id: openAction, label: l10n.actionOpen),
        NoticeAction(
          id: revealAction,
          label: TransferTexts(l10n).revealLabel(),
        ),
      ],
    ),
    NoticeCategory(
      id: textCategory,
      actions: [NoticeAction(id: copyAction, label: l10n.actionCopy)],
    ),
    NoticeCategory(
      id: failedCategory,
      actions: [NoticeAction(id: retryAction, label: l10n.actionRetry)],
    ),
    NoticeCategory(
      id: offerCategory,
      actions: [
        NoticeAction(id: acceptAction, label: l10n.actionAccept),
        NoticeAction(id: declineAction, label: l10n.actionDecline),
      ],
    ),
  ];

  static String noticeId(String transferId) => '$_prefix$transferId';

  void start() {
    _subscriptions
      ..add(feature.updates.listen((transfer) => unawaited(_show(transfer))))
      ..add(
        notifier.responses
            .where((response) => response.noticeId.startsWith(_prefix))
            .listen((response) => unawaited(_respond(response))),
      );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  /// Explains a drop that couldn't start, such as with no device connected.
  Future<void> explain(String title, String body) => notifier.show(
    LocalNotice(
      id: '${_prefix}problem',
      channel: .transfers,
      title: title,
      body: body,
    ),
  );

  Future<void> _show(Transfer transfer) async {
    final id = noticeId(transfer.id);
    final previous = _shown[transfer.id];
    final now = DateTime.now();
    final settled = !transfer.status.isActive || transfer.needsAnswer;
    if (!settled &&
        previous != null &&
        now.difference(previous) < progressInterval) {
      return;
    }

    _shown[transfer.id] = now;
    final notice = _noticeFor(id, transfer);
    if (notice == null) {
      _shown.remove(transfer.id);
      await notifier.cancel(id);
      return;
    }

    if (!transfer.status.isActive) {
      _shown.remove(transfer.id);
    }

    await notifier.show(notice);
  }

  LocalNotice? _noticeFor(String id, Transfer transfer) {
    final texts = TransferTexts(l10n);
    final device = transfer.deviceName;
    final title = texts.title(transfer);

    if (transfer.needsAnswer) {
      return LocalNotice(
        id: id,
        channel: .transfers,
        title: l10n.noticeOffer(device),
        body: [
          title,
          if (transfer.quickShare case final origin?)
            l10n.noticePin(origin.pin),
          if (transfer.isUnpaired && !transfer.isText)
            texts.size(transfer.totalBytes),
        ].join(' · '),
        category: offerCategory,
        groupKey: transfer.deviceId,
      );
    }

    return switch (transfer.status) {
      .waiting || .transferring || .verifying => switch (transfer.isText) {
        true => null,
        false => LocalNotice(
          id: id,
          channel: .transfers,
          title: switch (transfer.isOutgoing) {
            true => l10n.noticeSending(device),
            false => l10n.noticeReceiving(device),
          },
          body: [title, ?texts.speed(transfer)].join(' · '),
          category: progressCategory,
          groupKey: transfer.deviceId,
          silent: true,
          progress: transfer.progress,
        ),
      },
      .done => _doneNotice(id, transfer, texts),
      .failed when transfer.isPaused => LocalNotice(
        id: id,
        channel: .transfers,
        title: l10n.noticePaused(device),
        body: texts.paused(transfer),
        groupKey: transfer.deviceId,
        silent: true,
      ),
      .failed => LocalNotice(
        id: id,
        channel: .transfers,
        title: l10n.noticeFailed(device),
        body: texts.failure(transfer),
        category: switch (feature.canRetry(transfer)) {
          true => failedCategory,
          false => null,
        },
        groupKey: transfer.deviceId,
      ),
      .cancelled => null,
    };
  }

  LocalNotice? _doneNotice(String id, Transfer transfer, TransferTexts texts) {
    final device = transfer.deviceName;
    if (transfer.isOutgoing) {
      if (transfer.isText) {
        return null;
      }

      return LocalNotice(
        id: id,
        channel: .transfers,
        title: l10n.noticeSent(device),
        body: texts.title(transfer),
        groupKey: transfer.deviceId,
        silent: true,
      );
    }

    if (transfer.isText) {
      return LocalNotice(
        id: id,
        channel: .transfers,
        title: l10n.noticeText(device),
        body: transfer.text ?? '',
        category: textCategory,
        groupKey: transfer.deviceId,
      );
    }

    final folder = folderLabel?.call() ?? '';
    return LocalNotice(
      id: id,
      channel: .transfers,
      title: l10n.activityFrom(texts.title(transfer), device),
      body: switch (folder) {
        '' => l10n.activitySaved,
        final folder => l10n.activitySavedTo(folder),
      },
      category: filesCategory,
      groupKey: transfer.deviceId,
    );
  }

  Future<void> _respond(NoticeResponse response) async {
    final transferId = response.noticeId.substring(_prefix.length);
    final transfer = feature.registry[transferId];
    if (transfer == null) {
      return;
    }

    switch (response.actionId) {
      case openAction || null when transfer.status == .done:
        if (transfer.isText) {
          await onCopy(transfer.text ?? '');
          return;
        }

        await onOpen(transfer);
      case revealAction:
        await onReveal(transfer);
      case copyAction:
        await onCopy(transfer.text ?? '');
      case retryAction:
        await feature.retry(transfer.id);
      case cancelAction:
        await feature.cancel(transfer.id);
      case acceptAction:
        feature.answer(transfer.id, accept: true);
      case declineAction:
        feature.answer(transfer.id, accept: false);
    }
  }
}
