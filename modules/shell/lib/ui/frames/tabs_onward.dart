import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/view_models/view_models.dart';

/// Lets Tab leave the pane. The scope around a navigator sends Tab back to
/// its first stop after the last one, which keeps the device list out of
/// the keyboard's reach; here it goes on to what is around the pane.
class TabsOnward extends StatefulWidget {
  const TabsOnward({super.key, required this.child});

  final Widget child;

  @override
  State<TabsOnward> createState() => _TabsOnwardState();
}

class _TabsOnwardState extends State<TabsOnward> {
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
