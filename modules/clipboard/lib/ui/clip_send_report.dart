import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says right where Send clipboard was pressed how it went: "Sent to
/// Pixel 7", "Already sent", or why nothing went. Screen readers hear it
/// too, since a toast never takes focus.
void reportClipSend(
  BuildContext context,
  ClipSendResult result,
  String deviceName,
) {
  final l10n = context.clipboardL10n;
  final (message, type) = switch (result) {
    .sent => (l10n.sentTo(deviceName), MessageType.success),
    .duplicate => (l10n.resultDuplicate, MessageType.info),
    _ => (l10n.resultOf(result), MessageType.error),
  };

  switch (type) {
    case .error:
      context.toastError(message);
    case _:
      context.toast(message, type: type);
  }
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  ).ignore();
}
