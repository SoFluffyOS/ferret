import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/ui/widgets/app_icon.dart';
import 'package:protocol/notifications.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One app in the picker, with its switch.
class AppRow extends StatelessWidget {
  const AppRow({super.key, required this.app, required this.onChanged});

  final AppEntry app;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        children: [
          AppIcon(png: .fromList(app.iconPng), size: Spacing.d32),
          Spacing.h12,
          Expanded(
            child: Text(
              app.name,
              style: typography.base1.copyWith(color: palette.text),
              overflow: .ellipsis,
            ),
          ),
          Spacing.h12,
          SwitchToggle(value: app.allowed, onChanged: onChanged),
        ],
      ),
    );
  }
}
