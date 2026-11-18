import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How long to pause: an hour, until tomorrow, or until resumed.
class PauseDialog extends StatelessWidget {
  const PauseDialog({super.key, required this.controller});

  final PauseController controller;

  static Future<void> show(BuildContext context, PauseController controller) =>
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: context.shellL10n.cancel,
        barrierColor: const Color(0x99000000),
        pageBuilder: (_, _, _) => PauseDialog(controller: controller),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final now = DateTime.now();
    final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 8);
    final options = [
      (l10n.pauseOneHour, const Duration(hours: 1)),
      (l10n.pauseUntilTomorrow, tomorrowMorning.difference(now)),
      (l10n.pauseUntilResume, null),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d320),
        child: SurfaceCard(
          padding: EdgeInsets.all(Spacing.d16),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.pauseTitle,
                style: context.fluffyTheme.typography.title3.copyWith(
                  color: context.palette.text,
                ),
              ),
              Spacing.v6,
              Text(
                l10n.pauseBody,
                style: context.fluffyTheme.typography.body2.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
              Spacing.v16,
              for (final (label, duration) in options)
                Padding(
                  padding: EdgeInsets.only(bottom: Spacing.d8),
                  child: Button(
                    variant: .secondary,
                    label: label,
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.pause(duration: duration);
                    },
                  ),
                ),
              Button(
                variant: .ghost,
                label: l10n.cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
