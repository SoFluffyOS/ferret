import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A device's battery next to its status: "62%" with a bolt while it
/// charges, in the warning colour once it runs low.
class BatteryBadge extends StatelessWidget {
  const BatteryBadge({super.key, required this.battery});

  final DeviceBattery battery;

  static const lowPercent = 15;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final isLow = battery.percent <= lowPercent && !battery.charging;
    final color = switch (isLow) {
      true => palette.warning,
      false => palette.mutedText,
    };
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(battery.percent / 100);

    return Semantics(
      label: switch (battery.charging) {
        true => l10n.batteryCharging(percent),
        false => l10n.batteryLevel(percent),
      },
      excludeSemantics: true,
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(
            switch ((battery.charging, isLow)) {
              (true, _) => LucideIcons.batteryCharging,
              (false, true) => LucideIcons.batteryLow,
              (false, false) => LucideIcons.battery,
            },
            size: Spacing.d14,
            color: color,
          ),
          Spacing.horizontal(Spacing.d2),
          Text(percent, style: typography.caption1.copyWith(color: color)),
        ],
      ),
    );
  }
}
