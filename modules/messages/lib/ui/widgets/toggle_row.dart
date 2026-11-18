import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting with a title, an optional explanation and a switch.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.detail,
  });

  final String title;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
                if (detail case final explanation?) ...[
                  Spacing.vertical(Spacing.d2),
                  Text(
                    explanation,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
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
