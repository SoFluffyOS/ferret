import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phone_camera/feature/feature.dart';
import 'package:phone_camera/l10n/l10n.dart';
import 'package:phone_camera/models/models.dart';

/// A computer's requests for pictures as Activity lines: waiting (with
/// Cancel), arriving, "Photo from Pixel 7 · On your clipboard", or why
/// there is none.
List<ActivityItem> cameraActivity(
  CameraLocalizations l10n,
  CameraFeature feature,
) => [for (final job in feature.jobs.all) _itemOf(l10n, feature, job)];

ActivityItem _itemOf(
  CameraLocalizations l10n,
  CameraFeature feature,
  CaptureJob job,
) {
  final device = feature.host.displayNameOf(job.deviceId);
  final icon = switch (job.kind) {
    .photo => LucideIcons.camera,
    .document => LucideIcons.scanLine,
  };
  void dismiss() => feature.jobs.remove(job.id);
  void askAgain() => unawaited(feature.request(job.deviceId, kind: job.kind));

  switch (job.status) {
    case .asking:
      return ActivityItem(
        id: job.id,
        icon: icon,
        title: switch (job.kind) {
          .photo => l10n.activityWaiting(device),
          .document => l10n.activityWaitingScan(device),
        },
        detail: l10n.activityWaitingDetail(device),
        pinned: true,
        deviceId: job.deviceId,
        actions: [
          ActivityAction(
            label: l10n.cancel,
            onPressed: () => unawaited(feature.cancel(job.id)),
          ),
        ],
      );
    case .receiving:
      return ActivityItem(
        id: job.id,
        icon: icon,
        title: l10n.activityReceiving(device),
        pinned: true,
        progress: job.fraction,
        deviceId: job.deviceId,
      );
    case .done:
      final title = switch (job.kind) {
        .photo => l10n.activityPhoto(device),
        .document => l10n.activityScan(device),
      };
      return ActivityItem(
        id: job.id,
        icon: icon,
        title: title,
        detail: switch (job.onClipboard) {
          true => l10n.activityOnClipboard,
          false => l10n.activityInFolder,
        },
        at: job.startedAt,
        files: job.paths,
        deviceId: job.deviceId,
        tone: .success,
        private: PrivateContent(job.deviceId, cover: title),
        actions: [
          if (CameraFeature.imageTypeOf(job.paths.firstOrNull ?? '') != null)
            ActivityAction(
              label: l10n.copy,
              onPressed: () => unawaited(feature.copyAgain(job.id)),
            ),
        ],
        onDismiss: dismiss,
      );
    case .declined || .cancelled || .expired:
      return ActivityItem(
        id: job.id,
        icon: icon,
        title: switch (job.status) {
          .declined => l10n.endDeclined(device),
          .cancelled => l10n.endCancelled(device),
          _ => l10n.endExpired(device),
        },
        at: job.startedAt,
        deviceId: job.deviceId,
        tone: .muted,
        actions: [ActivityAction(label: l10n.tryAgain, onPressed: askAgain)],
        onDismiss: dismiss,
      );
    case .unsupported || .noPermission || .busy || .offline || .failed:
      return ActivityItem(
        id: job.id,
        icon: icon,
        title: switch (job.status) {
          .unsupported => l10n.endUnsupported(device),
          .noPermission => l10n.endNoPermission(device),
          .busy => l10n.endBusy(device),
          .offline => l10n.endOffline(device),
          _ => l10n.endFailed(device),
        },
        detail: switch (job.status) {
          .unsupported => l10n.endUnsupportedDetail,
          .noPermission => l10n.endNoPermissionDetail,
          _ => null,
        },
        at: job.startedAt,
        deviceId: job.deviceId,
        tone: .danger,
        actions: [
          if (job.status != .unsupported)
            ActivityAction(label: l10n.tryAgain, onPressed: askAgain),
        ],
        onDismiss: dismiss,
      );
  }
}
