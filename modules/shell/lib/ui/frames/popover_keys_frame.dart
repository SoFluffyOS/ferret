import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/pages.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// The menubar popover's keys, on every page in it: ⌘N adds a device, ⌘,
/// opens Settings, and Esc goes back a page, or closes the popover from
/// Home. ↓ from a page's last line goes on into what sits under the pages,
/// such as the shelf, and ↑ from there comes back to that line, the way
/// Tab goes round. The window has its menu bar for these instead.
class PopoverKeysFrame extends StatefulWidget {
  const PopoverKeysFrame({
    super.key,
    required this.navigatorKey,
    required this.onClose,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  /// Closes the popover.
  final VoidCallback onClose;

  final Widget child;

  /// Tab goes on from the last thing on a page to what sits outside the
  /// pages, such as the shelf, and around again: a page's own scope and
  /// the navigator's would keep it in the page.
  static void letTabLeavePages(NavigatorState? navigator) {
    FocusScopeNode? scope = navigator?.focusNode.enclosingScope;
    while (scope != null) {
      final parent = scope.enclosingScope;
      if (parent == null || parent == FocusManager.instance.rootScope) {
        return;
      }

      scope.traversalEdgeBehavior = .parentScope;
      scope = parent;
    }
  }

  @override
  State<PopoverKeysFrame> createState() => _PopoverKeysFrameState();
}

class _PopoverKeysFrameState extends State<PopoverKeysFrame> {
  final FocusNode _area = FocusNode(
    debugLabel: 'popover',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => PopoverKeysFrame.letTabLeavePages(
        widget.navigatorKey.currentState,
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _addDevice,
        const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
            context.read<WindowNavRegistry>().open(const SettingsDestination()),
        const SingleActivator(LogicalKeyboardKey.escape): _back,
      },
      child: Focus(
        focusNode: _area,
        onKeyEvent: _onKey,
        child: KeyboardLinesExit(
          onPastEnd: _intoBar,
          child: widget.child,
        ),
      ),
    );
  }

  /// ↑ under the pages goes back up to the page's last line.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final navigator = widget.navigatorKey.currentState;
    final focus = FocusManager.instance.primaryFocus;
    if (event is KeyUpEvent ||
        event.logicalKey != LogicalKeyboardKey.arrowUp ||
        navigator == null ||
        focus == null ||
        _isInPages(focus, navigator) ||
        HardwareKeyboard.instance.isMetaPressed) {
      return .ignored;
    }

    final lines = KeyboardLines.onTopOf(navigator);
    if (lines == null || !lines.move(-1)) {
      return .ignored;
    }

    return .handled;
  }

  /// Focuses the widest stop under the pages: the shelf's box rather than
  /// its small buttons.
  void _intoBar() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    FocusNode? widest;
    for (final stop in _area.traversalDescendants) {
      if (stop.context == null ||
          stop is FocusScopeNode ||
          _isInPages(stop, navigator)) {
        continue;
      }

      if (widest == null || stop.rect.width > widest.rect.width) {
        widest = stop;
      }
    }

    widest?.requestFocus();
  }

  /// Whether [node] is on a page: under the navigator's scope, which holds
  /// each page's own.
  static bool _isInPages(FocusNode node, NavigatorState navigator) {
    final pages = navigator.focusNode.enclosingScope ?? navigator.focusNode;
    return node == pages || node.ancestors.contains(pages);
  }

  void _addDevice() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    unawaited(navigator.push(ferretRoute<void>(const PairPage())));
  }

  void _back() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      widget.onClose();
      return;
    }

    unawaited(navigator.maybePop());
  }
}
