import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Restarting this Mac in 8 seconds" with one button: Cancel. Shown on
/// the computer for the whole countdown.
class CountdownDialog extends StatelessWidget {
  const CountdownDialog({
    super.key,
    required this.countdown,
    required this.onCancel,
    this.computer,
    this.clock = DateTime.now,
  });

  final ActionCountdown countdown;
  final VoidCallback onCancel;

  /// What to call this computer. Left out, the one the app runs on.
  final ComputerKind? computer;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;

    return DialogCard(
      title: SecondsLeft(
        countdown: countdown,
        clock: clock,
        builder: (context, seconds) => Text(
          l10n.countdownTitleOf(
            countdown,
            computer ?? ComputerKind.here,
            seconds,
          ),
        ),
      ),
      content: Text(l10n.countdownBody(countdown.deviceName)),
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.cancel,
          tooltip: l10n.cancel,
          onPressed: onCancel,
        ),
      ],
    );
  }
}
