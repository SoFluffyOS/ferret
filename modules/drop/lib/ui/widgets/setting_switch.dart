import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting that is on or off, with a line saying what it does.
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Row(
      children: [
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
                body,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
            ],
          ),
        ),
        Spacing.h12,
        SwitchToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
