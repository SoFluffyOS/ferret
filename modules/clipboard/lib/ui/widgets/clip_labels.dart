import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';

/// Plain-words labels for clips, shared by the card and its tests.
extension ClipLabels on ClipboardLocalizations {
  /// "Copied from Pixel · just now", "Sent to Laptop · 3 min ago".
  String statusOf(ClipEntry entry, DateTime now) =>
      statusWithTime(_what(entry), timeAgo(entry.at, now));

  String timeAgo(DateTime at, DateTime now) {
    final elapsed = now.difference(at);
    if (elapsed.inMinutes < 1) {
      return timeJustNow;
    }

    if (elapsed.inHours < 1) {
      return timeMinutes(elapsed.inMinutes);
    }

    if (elapsed.inDays < 1) {
      return timeHours(elapsed.inHours);
    }

    return timeDays(elapsed.inDays);
  }

  String resultOf(ClipSendResult result) => switch (result) {
    .sent => resultSent,
    .nothingToSend => resultNothingToSend,
    .duplicate => resultDuplicate,
    .sensitive => resultSensitive,
    .imagesOff => resultImagesOff,
    .tooLarge => resultTooLarge,
    .noDevices => resultNoDevices,
    .failed => resultFailed,
  };

  String _what(ClipEntry entry) {
    final devices = entry.deviceNames.join(', ');
    return switch (entry.skip) {
      .sensitive => skippedSensitive,
      .imagesOff => skippedImagesOff,
      .tooLarge => skippedTooLarge,
      .noDevices => sentNowhere,
      .writeFailed => writeFailed(devices),
      .none => switch (entry.direction) {
        .sent => sentTo(devices),
        .received => switch (entry.onClipboard) {
          true => copiedFrom(devices),
          false => waitingToCopyFrom(devices),
        },
      },
    };
  }
}
