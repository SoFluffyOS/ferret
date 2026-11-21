import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One Connection Doctor result: an icon for how it went and what it means.
class DoctorCheckRow extends StatelessWidget {
  const DoctorCheckRow({
    super.key,
    required this.status,
    required this.message,
  });

  final DoctorStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.shellL10n;
    final (icon, color, spoken) = switch (status) {
      .running => (
        LucideIcons.loaderCircle,
        palette.mutedText,
        l10n.spokenChecking,
      ),
      .ok => (LucideIcons.circleCheck, palette.success, l10n.spokenOk),
      .warning => (
        LucideIcons.triangleAlert,
        palette.warning,
        l10n.spokenWarning,
      ),
      .problem => (LucideIcons.circleX, palette.danger, l10n.spokenProblem),
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: .start,
          children: [
            switch (status) {
              .running => Semantics(
                label: spoken,
                child: SizedBox.square(
                  dimension: Spacing.d18,
                  child: Center(
                    child: FluffySpinner(
                      size: Spacing.d14,
                      strokeWidth: Spacing.d1 + Spacing.d0,
                      color: color,
                    ),
                  ),
                ),
              ),
              _ => Icon(
                icon,
                size: Spacing.d18,
                color: color,
                semanticLabel: spoken,
              ),
            },
            Spacing.h12,
            Expanded(
              child: Text(
                message,
                style: context.fluffyTheme.typography.body2.copyWith(
                  color: palette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
