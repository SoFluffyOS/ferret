import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Asks whether to pair with a device that shows the same six digits.
class PairingPromptDialog extends StatelessWidget {
  const PairingPromptDialog({super.key, required this.prompt});

  final PairingPrompt prompt;

  static Future<void> show(BuildContext context, PairingPrompt prompt) async {
    final navigator = Navigator.of(context);
    var open = true;

    // The request can end without an answer here: it times out, or the
    // other device gives up. Close the dialog so the next one can show.
    unawaited(
      prompt.decision.then((_) {
        if (open) {
          navigator.pop();
        }
      }),
    );

    final accepted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99000000),
      pageBuilder: (_, _, _) => PairingPromptDialog(prompt: prompt),
    );
    open = false;

    switch (accepted) {
      case true:
        prompt.accept();
      case _:
        prompt.reject();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final name = prompt.device.name;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d320),
        child: SurfaceCard(
          padding: EdgeInsets.all(Spacing.d20),
          child: Column(
            mainAxisSize: .min,
            children: [
              Text(
                l10n.promptTitle(name),
                textAlign: .center,
                style: typography.title3.copyWith(color: palette.text),
              ),
              Spacing.v16,
              ComparisonCode(code: prompt.code),
              Spacing.v12,
              Text(
                l10n.promptBody(name),
                textAlign: .center,
                style: typography.body2.copyWith(color: palette.mutedText),
              ),
              Spacing.vertical(Spacing.d20),
              Row(
                children: [
                  Expanded(
                    child: Button(
                      variant: .secondary,
                      label: l10n.promptReject,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Button(
                      variant: .primary,
                      label: l10n.promptAccept,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
