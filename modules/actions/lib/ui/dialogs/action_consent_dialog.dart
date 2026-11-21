import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/widgets/widgets.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Let Pixel 7 restart this Mac?" with Always allow, Allow once and Don't
/// allow. For one of the owner's own actions it shows the command line
/// that will run, word for word. Closing it answers nothing: the home card
/// still asks.
class ActionConsentDialog extends StatelessWidget {
  const ActionConsentDialog({
    super.key,
    required this.ask,
    required this.onAnswer,
    this.computer,
  });

  final ActionAsk ask;
  final ValueChanged<ActionChoice> onAnswer;

  /// What to call this computer. Left out, the one the app runs on.
  final ComputerKind? computer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;
    final commandLine = ask.action.commandLine;

    return FerretDialogCard(
      title: Text(l10n.consentTitleOf(ask, computer ?? ComputerKind.here)),
      content: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          if (commandLine.isNotEmpty) ...[
            Text(l10n.consentCommandLabel),
            Spacing.v8,
            CommandBlock(commandLine),
            Spacing.v12,
          ],
          if (ask.action.countsDown) ...[
            Text(l10n.consentCountsDown),
            Spacing.v8,
          ],
          Text(l10n.consentBody(ask.deviceName)),
        ],
      ),
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.allowAlways,
          tooltip: l10n.allowAlways,
          onPressed: () => onAnswer(.always),
        ),
        Spacing.v8,
        GhostButton(
          mainAxisSize: .min,
          label: l10n.allowOnce,
          tooltip: l10n.allowOnce,
          onPressed: () => onAnswer(.allowOnce),
        ),
        Spacing.v8,
        GhostButton(
          mainAxisSize: .min,
          label: l10n.dontAllow,
          tooltip: l10n.dontAllow,
          onPressed: () => onAnswer(.deny),
        ),
      ],
    );
  }
}
