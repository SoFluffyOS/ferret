import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/surface_card.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The colour a card gives its icon or subtitle, by meaning.
enum FeatureTone { normal, muted, accent, success, warning, danger }

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
    this.iconTone = .normal,
    this.subtitleTone = .muted,
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

  /// Such as success or danger for how a ring ended.
  final FeatureTone iconTone;

  /// Such as accent for an unread count, or danger for missing access.
  final FeatureTone subtitleTone;

  /// Grows with the text, up to twice its size, so the icon still reads
  /// next to a large title.
  static double _iconSize(BuildContext context) =>
      MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: 2)
          .scale(
            Spacing.d18,
          );

  static double get _iconGap => Spacing.d12;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final iconSize = _iconSize(context);

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
                child: Icon(
                  icon,
                  size: iconSize,
                  color: _color(palette, iconTone),
                ),
              ),
              Spacing.horizontal(_iconGap),
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
          // The content and the buttons start under the title's text,
          // not under the icon.
          if (children.isNotEmpty || actions.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(start: iconSize + _iconGap),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
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
            ),
        ],
      ),
    );
  }

  Color _color(FerretPalette palette, FeatureTone tone) => switch (tone) {
    .normal => palette.text,
    .muted => palette.mutedText,
    .accent => palette.link,
    .success => palette.success,
    .warning => palette.warning,
    .danger => palette.danger,
  };
}
