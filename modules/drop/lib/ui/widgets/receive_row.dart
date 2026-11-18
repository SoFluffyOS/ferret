import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Whether devices outside Ferret, such as LocalSend apps or Quick Share
/// on phones, can send here right now, with the countdown while the
/// window is open and one button to turn it on or off.
class ReceiveRow extends StatelessWidget {
  const ReceiveRow({
    super.key,
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onAction,
    this.icon = LucideIcons.radio,
    this.hasProblem = false,
  });

  final String title;

  /// Where receiving stands, in plain words.
  final String status;
  final String actionLabel;

  /// Null while it is turning on.
  final VoidCallback? onAction;
  final IconData icon;
  final bool hasProblem;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final statusColor = switch (hasProblem) {
      true => palette.warning,
      false => palette.mutedText,
    };

    return Row(
      children: [
        Icon(icon, size: Spacing.d16, color: palette.text),
        Spacing.h8,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                title,
                style: typography.base1.copyWith(color: palette.text),
              ),
              Spacing.vertical(Spacing.d2),
              Text(
                status,
                style: typography.caption1.copyWith(color: statusColor),
              ),
            ],
          ),
        ),
        if (onAction case final action?) ...[
          Spacing.h12,
          Button(
            mainAxisSize: .min,
            variant: .ghost,
            label: actionLabel,
            onPressed: action,
          ),
        ],
      ],
    );
  }
}
