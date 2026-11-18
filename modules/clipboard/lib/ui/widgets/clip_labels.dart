import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';

/// Plain-words labels for what happened to a Send clipboard.
extension ClipLabels on ClipboardLocalizations {
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
}
