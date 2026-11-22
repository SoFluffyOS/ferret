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

    final text = Column(
      crossAxisAlignment: .start,
      children: [
        Text(title, style: typography.base1.copyWith(color: palette.text)),
        Spacing.vertical(Spacing.d2),
        Text(status, style: typography.caption1.copyWith(color: statusColor)),
      ],
    );

    final titleStyle = typography.base1;
    final titleLine =
        MediaQuery.textScalerOf(context).scale(titleStyle.fontSize ?? 16) *
        (titleStyle.height ?? 1.2);

    return Row(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          height: titleLine,
          child: Center(
            child: Icon(icon, size: Spacing.d16, color: palette.text),
          ),
        ),
        Spacing.h8,
        Expanded(
          child: switch (onAction) {
            // On a small phone with large text the button goes under the
            // words instead of breaking "LocalSend" in two.
            final action? => BesideOrBelow(
              gap: Spacing.d12,
              maxShare: 0.5,
              children: [
                text,
                GhostButton(
                  mainAxisSize: .min,
                  label: actionLabel,
                  onPressed: action,
                ),
              ],
            ),
            null => text,
          },
        ),
      ],
    );
  }
}
