import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/activity_pane_frame.dart';
import 'package:shell/ui/frames/needs_you_frame.dart';
import 'package:shell/ui/frames/pane_drop_frame.dart';
import 'package:shell/ui/frames/pane_toolbar_frame.dart';
import 'package:shell/ui/frames/sliding_sidebar.dart';
import 'package:shell/ui/frames/tabs_onward.dart';
import 'package:shell/ui/frames/window_menu_frame.dart';
import 'package:shell/ui/frames/window_navigator.dart';
import 'package:shell/ui/frames/window_title_frame.dart';
import 'package:shell/view_models/view_models.dart';

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

    return WindowNavigator(
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
            SlidingSidebar(
              isHidden: isSidebarHidden,
              width: WindowLayout.sidebarWidth(
                context.screenSize,
                textScaler: MediaQuery.textScalerOf(context),
              ),
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
                              child: TabsOnward(child: child),
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
