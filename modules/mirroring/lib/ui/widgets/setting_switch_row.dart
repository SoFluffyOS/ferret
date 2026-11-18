import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting with a title, a line that explains it, and a switch.
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
    this.tag,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// A word next to the title, such as "Experimental".
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Wrap(
                  spacing: Spacing.d8,
                  runSpacing: Spacing.d4,
                  crossAxisAlignment: .center,
                  children: [
                    Text(
                      title,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                    if (tag case final tag?) Tag(tag, color: palette.warning),
                  ],
                ),
                Spacing.vertical(Spacing.d2),
                Text(
                  body,
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Spacing.h12,
          SwitchToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
