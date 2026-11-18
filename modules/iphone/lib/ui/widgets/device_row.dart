import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A paired device the person can pick as their iPhone.
class DeviceRow extends StatelessWidget {
  const DeviceRow({
    super.key,
    required this.name,
    required this.actionLabel,
    required this.onAction,
    this.detail,
  });

  final String name;

  /// Such as "Connected now".
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d4),
      child: Row(
        children: [
          Icon(LucideIcons.smartphone, size: Spacing.d16, color: palette.text),
          Spacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  name,
                  style: typography.body2.copyWith(color: palette.text),
                  overflow: .ellipsis,
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: typography.caption1.copyWith(
                      color: palette.success,
                    ),
                  ),
              ],
            ),
          ),
          Spacing.h8,
          Button(
            mainAxisSize: .min,
            variant: .ghost,
            label: actionLabel,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
