import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/window_more_menu.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The row at the top of a window's content pane: the button that hides
/// or shows the device list, what the pane shows, and on the trailing
/// side the Activity pane's button and, off a Mac, the ••• menu.
class PaneToolbarFrame extends StatelessWidget {
  const PaneToolbarFrame({super.key, required this.title});

  final PaneTitle title;

  static double get height => Spacing.d44;

  @override
  Widget build(BuildContext context) {
    final isSidebarHidden = context.select<WindowNavViewModel, bool>(
      (viewModel) => viewModel.isSidebarHidden,
    );
    final isActivityPaneHidden = context.select<WindowNavViewModel, bool>(
      (viewModel) => viewModel.isActivityPaneHidden,
    );
    final hasActivityPane =
        context.select<WindowNavViewModel, bool>(
          (viewModel) => viewModel.selection is DeviceDestination,
        ) &&
        WindowLayout.showsActivityPane(context);
    final nav = context.read<WindowNavViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final platform = defaultTargetPlatform;
    final side = PageInsets.side(context.screenSize);

    return SizedBox(
      height: height,
      child: Padding(
        // The buttons' glyphs, not the room around them, line up with
        // the page's content.
        padding: EdgeInsets.symmetric(horizontal: side - _buttonInset),
        child: FocusTraversalGroup(
          child: Row(
            children: [
              _ToolbarButton(
                icon: switch (isSidebarHidden) {
                  true => LucideIcons.panelLeftOpen,
                  false => LucideIcons.panelLeftClose,
                },
                label: switch (isSidebarHidden) {
                  true => l10n.sidebarShow,
                  false => l10n.sidebarHide,
                },
                keys: WindowShortcuts.activatorOf(.toggleSidebar, platform),
                onTap: nav.toggleSidebar,
              ),
              Spacing.h8,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(
                      text: title.place,
                      children: [
                        if (title.deviceName case final deviceName?)
                          TextSpan(
                            text: '  $deviceName',
                            style: typography.base2.copyWith(
                              color: palette.mutedText,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.base1.copyWith(
                      color: palette.text,
                      fontWeight: .w600,
                    ),
                  ),
                ),
              ),
              if (hasActivityPane)
                _ToolbarButton(
                  icon: switch (isActivityPaneHidden) {
                    true => LucideIcons.panelRightOpen,
                    false => LucideIcons.panelRightClose,
                  },
                  label: switch (isActivityPaneHidden) {
                    true => l10n.activityPaneShow,
                    false => l10n.activityPaneHide,
                  },
                  keys: WindowShortcuts.activatorOf(
                    .toggleActivityPane,
                    platform,
                  ),
                  onTap: nav.toggleActivityPane,
                ),
              if (platform != .macOS) const WindowMoreMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

double get _buttonInset => Spacing.d6;

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.keys,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final SingleActivator? keys;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      tooltip: WindowShortcuts.hint(label, keys, defaultTargetPlatform),
      semanticLabel: label,
      hoverOverlayBorderRadius: Corners.row,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(_buttonInset),
        child: Icon(icon, size: Spacing.d18, color: context.palette.text),
      ),
    );
  }
}
