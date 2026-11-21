import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/widgets/widgets.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Locking this Mac in 8 seconds · Pixel 7 left" with one button:
/// Cancel. Shown on the computer for the whole countdown.
class LeaveCountdownDialog extends StatelessWidget {
  const LeaveCountdownDialog({
    super.key,
    required this.countdown,
    required this.onCancel,
    this.computer,
    this.clock = DateTime.now,
  });

  final LeaveCountdown countdown;
  final VoidCallback onCancel;

  /// What to call this computer. Left out, the one the app runs on.
  final ComputerKind? computer;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;

    return FerretDialogCard(
      title: SecondsLeft(
        endsAt: countdown.endsAt,
        clock: clock,
        builder: (context, seconds) => Text(
          l10n.leaveCountdownTitle(
            (computer ?? ComputerKind.here).name,
            seconds,
          ),
        ),
      ),
      content: Text(l10n.leaveCountdownBody(countdown.deviceName)),
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
