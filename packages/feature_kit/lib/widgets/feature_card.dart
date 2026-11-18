import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/surface_card.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The one look for a feature's home card: icon and title, a short muted
/// line, then the content and the actions. Use it so every card reads the
/// same.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.children = const [],
    this.actions = const [],
    this.onTap,
  });

  final IconData icon;
  final String title;

  /// One or two short lines, such as "Copied from Pixel · just now".
  final String? subtitle;

  /// A small widget at the end of the title row, such as a count or a close
  /// button.
  final Widget? trailing;

  /// The content under the title, such as a preview or a progress bar.
  final List<Widget> children;

  /// Buttons in a row at the bottom.
  final List<Widget> actions;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            crossAxisAlignment: .start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: Spacing.d1),
                child: Icon(icon, size: Spacing.d18, color: palette.text),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      title,
                      style: typography.base1.copyWith(color: palette.text),
                      overflow: .ellipsis,
                    ),
                    if (subtitle case final subtitle?) ...[
                      Spacing.vertical(Spacing.d2),
                      Text(
                        subtitle,
                        style: typography.caption1.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing case final trailing?) ...[Spacing.h8, trailing],
            ],
          ),
          if (children.isNotEmpty) ...[Spacing.v12, ...children],
          if (actions.isNotEmpty) ...[
            Spacing.v12,
            Wrap(
              spacing: Spacing.d8,
              runSpacing: Spacing.d8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
