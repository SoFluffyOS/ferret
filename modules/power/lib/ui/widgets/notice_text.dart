import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A short line under a group: a hint in grey, or a problem in colour.
class NoticeText extends StatelessWidget {
  const NoticeText(this.text, {super.key, this.tone = .muted});

  final String text;
  final FeatureTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Text(
      text,
      style: context.fluffyTheme.typography.caption1.copyWith(
        color: switch (tone) {
          .warning => palette.warning,
          .danger => palette.danger,
          .success => palette.success,
          .accent => palette.link,
          .normal => palette.text,
          .muted => palette.mutedText,
        },
      ),
    );
  }
}
