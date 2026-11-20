import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One allowed browser: its name, whether it's connected, and Remove.
class BrowserClientRow extends StatelessWidget {
  const BrowserClientRow({
    super.key,
    required this.name,
    required this.isConnected,
    required this.onRemove,
  });

  final String name;
  final bool isConnected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.handoffL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PageInsets.row,
        vertical: Spacing.d8,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.globe, size: Spacing.d18, color: palette.mutedText),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  name,
                  style: typography.body2.copyWith(color: palette.text),
                  overflow: .ellipsis,
                ),
                Text(
                  switch (isConnected) {
                    true => l10n.browserClientConnected,
                    false => l10n.browserClientOffline,
                  },
                  style: typography.caption1.copyWith(
                    color: switch (isConnected) {
                      true => palette.success,
                      false => palette.mutedText,
                    },
                  ),
                ),
              ],
            ),
          ),
          Spacing.h8,
          GhostButton(
            label: l10n.browserClientRemove,
            mainAxisSize: .min,
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d12,
              vertical: Spacing.d6,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
