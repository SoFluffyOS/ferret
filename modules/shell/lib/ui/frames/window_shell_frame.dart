import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/activity_pane_frame.dart';
import 'package:shell/ui/frames/needs_you_frame.dart';
import 'package:shell/ui/frames/pane_drop_frame.dart';
import 'package:shell/ui/frames/pane_toolbar_frame.dart';
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
    final title = PaneTitles.of(context);

    return WindowMenuFrame(
      child: ColoredBox(
        color: context.palette.background,
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            _SlidingSidebar(
              isHidden: isSidebarHidden,
              width: WindowLayout.sidebarWidth(context.screenSize),
            ),
            Expanded(
              child: PaneDropFrame(
                child: SafeArea(
                  left: false,
                  right: false,
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      PaneToolbarFrame(title: title),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: PageInsets.side(context.screenSize),
                        ),
                        child: const AdaptiveContent(child: NeedsYouFrame()),
                      ),
                      // A route hides whatever was drawn before it from screen
                      // readers, up to the nearest container: without this one
                      // the pane's pages would take the device list with them.
                      Expanded(
                        child: Semantics(
                          container: true,
                          child: ClipRect(
                            child: PaneToolbarScope(
                              title: title.place,
                              child: _TabsOnward(child: child),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

/// Lets Tab leave the pane. The scope around a navigator sends Tab back to
/// its first stop after the last one, which keeps the device list out of
/// the keyboard's reach; here it goes on to what is around the pane.
class _TabsOnward extends StatefulWidget {
  const _TabsOnward({required this.child});

  final Widget child;

  @override
  State<_TabsOnward> createState() => _TabsOnwardState();
}

class _TabsOnwardState extends State<_TabsOnward> {
  @override
  void initState() {
    super.initState();
    final navigatorKey = context.read<WindowNavViewModel>().navigatorKey;
    // The navigator's scope is built below this widget, in the same frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey
              .currentState
              ?.focusNode
              .enclosingScope
              ?.traversalEdgeBehavior =
          TraversalEdgeBehavior.parentScope;
    });
  }

  /// A page with nothing to press, such as an empty Activity, has no stop
  /// for Tab to leave from: the keyboard sits on the page itself, and Tab
  /// would come back to it for ever. From there Tab goes on as it does
  /// after a page's last stop.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || event.logicalKey != LogicalKeyboardKey.tab) {
      return .ignored;
    }

    final page = FocusManager.instance.primaryFocus;
    if (page is! FocusScopeNode || page.traversalDescendants.isNotEmpty) {
      return .ignored;
    }

    final around = page.enclosingScope;
    if (around == null) {
      return .ignored;
    }

    final moved = switch (HardwareKeyboard.instance.isShiftPressed) {
      true => around.previousFocus(),
      false => around.nextFocus(),
    };
    return switch (moved) {
      true => .handled,
      false => .ignored,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
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

/// The device list, which slides out of the window when it is hidden and
/// back in when it is shown. Hidden, it takes no room and is out of the
/// keyboard's and the screen reader's reach.
class _SlidingSidebar extends StatefulWidget {
  const _SlidingSidebar({required this.isHidden, required this.width});

  final bool isHidden;
  final double width;

  @override
  State<_SlidingSidebar> createState() => _SlidingSidebarState();
}

class _SlidingSidebarState extends State<_SlidingSidebar>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 220);

  late final AnimationController _shown = AnimationController(
    vsync: this,
    duration: _duration,
    value: switch (widget.isHidden) {
      true => 0,
      false => 1,
    },
  )..addStatusListener(_onStatus);

  @override
  void didUpdateWidget(_SlidingSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHidden == oldWidget.isHidden) {
      return;
    }

    final target = switch (widget.isHidden) {
      true => 0.0,
      false => 1.0,
    };
    if (context.reducesMotion) {
      _shown.value = target;
      return;
    }

    _shown.animateTo(target, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  /// Rebuilds once it is all the way out, to take the list off the tree.
  void _onStatus(AnimationStatus status) {
    if (!status.isAnimating) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHidden && _shown.value == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _shown,
      builder: (context, child) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          widthFactor: _shown.value,
          child: child,
        ),
      ),
      child: ExcludeFocus(
        excluding: widget.isHidden,
        child: SizedBox(width: widget.width, child: const SidebarFrame()),
      ),
    );
  }
}
