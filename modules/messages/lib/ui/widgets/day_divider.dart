import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The day above the first text of each day in a thread.
class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: Spacing.d12),
    child: Center(
      child: Text(
        label,
        style: context.fluffyTheme.typography.caption2.copyWith(
          color: context.palette.mutedText,
        ),
      ),
    ),
  );
}
