import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A titled block of help: a heading and what to do.
class HelpSection extends StatelessWidget {
  const HelpSection({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d12),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SectionTitle(title),
          SurfaceCard(
            child: Text(
              body,
              style: typography.body2.copyWith(color: palette.text),
            ),
          ),
        ],
      ),
    );
  }
}
