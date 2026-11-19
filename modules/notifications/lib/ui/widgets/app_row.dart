import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/ui/widgets/app_icon.dart';
import 'package:protocol/notifications.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One app in the picker, with its switch: a row of a `GroupedCard`.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.app,
    required this.value,
    required this.onChanged,
  });

  final AppEntry app;

  /// Whether the app's notifications come through.
  final bool value;
  final ValueChanged<bool> onChanged;

  /// How wide the icon is, for the card's lines to start after it.
  static double get iconSize => Spacing.d32;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GroupedRow(
        leading: AppIcon(png: .fromList(app.iconPng), size: iconSize),
        title: app.name,
        titleMaxLines: 1,
        trailing: SwitchToggle(value: value, onChanged: onChanged),
      ),
    );
  }
}
