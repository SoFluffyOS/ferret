import 'package:media/l10n/l10n.dart';
import 'package:media/view_models/view_models.dart';

/// The plain-words text for a [MediaNotice].
extension MediaNoticeText on MediaLocalizations {
  String noticeText(MediaNotice notice) => switch (notice) {
    CommandNotice(:final outcome, :final deviceName) => switch (outcome) {
      .unreachable => deviceUnreachable(deviceName),
      .unknownPlayer => playerGone(deviceName),
      .notShared => deviceNotSharing(deviceName),
      .unsupported => commandUnsupported,
      .failed || .ok => commandFailed(deviceName),
    },
    ContinueNotice(:final reason, :final deviceName, :final appName) =>
      switch (reason) {
        .noLink => continueNoLink(appName),
        .unreachable => deviceUnreachable(deviceName),
        .playerGone => playerGone(deviceName),
        .notShared => deviceNotSharing(deviceName),
        .openFailed => continueOpenFailed(deviceName),
      },
  };
}
