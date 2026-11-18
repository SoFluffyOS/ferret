import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/activity_pane_frame.dart';
import 'package:shell/ui/frames/sidebar_frame.dart';
import 'package:shell/ui/frames/window_menu_frame.dart';
import 'package:shell/ui/frames/window_title_frame.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Arranges a view around its navigator by the view's size. A small view
/// (a phone, the popover) is the navigator alone, as it always was. With
/// more room the navigator becomes the content pane next to the device
/// list, so every page the app pushes lands in the pane.
class WindowShellFrame extends StatelessWidget {
  const WindowShellFrame({super.key, required this.child, this.onTitle});

  /// The view's navigator.
  final Widget child;

  /// Hears what the view shows, for a window's title bar.
  final void Function(String title)? onTitle;

  @override
  Widget build(BuildContext context) {
    if (!WindowLayout.splits(context)) {
      return child;
    }

    final isSidebarHidden = context.select<WindowNavViewModel, bool>(
      (viewModel) => viewModel.isSidebarHidden,
    );

    return _WindowNavigator(
      child: _Framed(
        onTitle: onTitle,
        child: _split(context, isSidebarHidden),
      ),
    );
  }

  Widget _split(BuildContext context, bool isSidebarHidden) {
    return WindowMenuFrame(
      child: ColoredBox(
        color: context.palette.background,
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            switch (isSidebarHidden) {
              true => const _SidebarStrip(),
              false => SizedBox(
                width: WindowLayout.sidebarWidth(context.screenSize),
                child: const SidebarFrame(),
              ),
            },
            Expanded(child: ClipRect(child: child)),
            const ActivityPaneFrame(),
          ],
        ),
      ),
    );
  }
}

class _Framed extends StatelessWidget {
  const _Framed({required this.onTitle, required this.child});

  final void Function(String title)? onTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onTitle = this.onTitle;
    if (onTitle == null) {
      return child;
    }

    return WindowTitleFrame(onTitle: onTitle, child: child);
  }
}

/// A navigator around the whole window, above the pane's own. Dialogs go
/// to the outermost navigator, so they cover the device list too instead of
/// sitting inside the pane.
class _WindowNavigator extends StatelessWidget {
  const _WindowNavigator({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _WindowContent(
      content: child,
      child: Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, _, _) => _WindowContent.of(context),
        ),
      ),
    );
  }
}

/// Hands the window's content to the one route of [_WindowNavigator], which
/// is built once and would otherwise keep the first content it saw.
class _WindowContent extends InheritedWidget {
  const _WindowContent({required this.content, required super.child});

  final Widget content;

  static Widget of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WindowContent>()?.content ??
      const SizedBox.shrink();

  @override
  bool updateShouldNotify(_WindowContent oldWidget) =>
      content != oldWidget.content;
}

/// What is left of a hidden device list: the way to bring it back, where
/// the list was.
class _SidebarStrip extends StatelessWidget {
  const _SidebarStrip();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ColoredBox(
      color: palette.surface,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.all(Spacing.d8),
          child: Align(
            alignment: .topCenter,
            child: Tappable(
              tooltip: context.shellL10n.sidebarShow,
              onTap: context.read<WindowNavViewModel>().toggleSidebar,
              child: Padding(
                padding: EdgeInsets.all(Spacing.d6),
                child: Icon(
                  LucideIcons.panelLeftOpen,
                  size: Spacing.d18,
                  color: palette.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
