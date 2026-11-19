import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The title bar of a page with a fixed layout: Back, the title, then
/// [actions].
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    this.actions = const [],
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Spacing.d12,
        Spacing.d12,
        Spacing.d12,
        Spacing.d8,
      ),
      child: Row(
        children: [
          Tappable(
            tooltip: backLabel,
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d4),
              child: DirectionalIcon(
                LucideIcons.chevronLeft,
                size: Spacing.d20,
                color: palette.text,
              ),
            ),
          ),
          Spacing.h4,
          Expanded(
            child: Text(
              title,
              style: typography.title2.copyWith(color: palette.text),
              overflow: .ellipsis,
              maxLines: 1,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
