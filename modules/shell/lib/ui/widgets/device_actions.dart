import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/window_commands.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What to do with a device, as a few buttons: the first [shown] of
/// [actions], the first one filled, and the rest behind "More". One action
/// too many is shown as a button: a menu of one helps nobody.
class DeviceActions extends StatelessWidget {
  const DeviceActions({
    super.key,
    required this.actions,
    required this.moreLabel,
    this.shown = 3,
    this.hasPrimary = true,
  });

  /// Most wanted first.
  final List<FeatureAction> actions;
  final String moreLabel;
  final int shown;

  /// Whether the first action is the screen's one filled button.
  final bool hasPrimary;

  @override
  Widget build(BuildContext context) {
    final fitsAll = actions.length <= shown + 1;
    final buttons = switch (fitsAll) {
      true => actions,
      false => actions.sublist(0, shown),
    };
    final behindMore = actions.sublist(buttons.length);

    return Wrap(
      spacing: Spacing.d8,
      runSpacing: Spacing.d8,
      children: [
        for (final (position, action) in buttons.indexed)
          Button(
            mainAxisSize: .min,
            variant: switch (position == 0 && hasPrimary) {
              true => .primary,
              false => .ghost,
            },
            label: action.label,
            icon: Icon(action.icon, size: Spacing.d16),
            onPressed: action.onPressed,
          ),
        if (behindMore.isNotEmpty)
          MenuButton(
            icon: LucideIcons.ellipsis,
            tooltip: moreLabel,
            label: moreLabel,
            entries: [
              for (final action in behindMore)
                if (action.onPressed case final onPressed?)
                  MenuEntry(
                    label: WindowCommands.buttonInMenu(
                      context.shellL10n,
                      action.label,
                    ),
                    icon: action.icon,
                    onSelected: onPressed,
                  ),
            ],
          ),
      ],
    );
  }
}
