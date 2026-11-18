import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final (icon, color) = switch (status) {
      .running => (LucideIcons.loaderCircle, palette.mutedText),
      .ok => (LucideIcons.circleCheck, palette.success),
      .warning => (LucideIcons.triangleAlert, const Color(0xFFFF9F0A)),
      .problem => (LucideIcons.circleX, palette.danger),
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Icon(icon, size: Spacing.d18, color: color),
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
    );
  }
}
