import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/pair_page.dart';

/// The menubar popover's keys, on every page in it: ⌘N adds a device, ⌘,
/// opens Settings, and Esc goes back a page, or closes the popover from
/// Home. The window has its menu bar for these instead.
class PopoverKeysFrame extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _addDevice,
        const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
            context.read<WindowNavRegistry>().open(const SettingsDestination()),
        const SingleActivator(LogicalKeyboardKey.escape): _back,
      },
      child: child,
    );
  }

  void _addDevice() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    unawaited(navigator.push(ferretRoute<void>(const PairPage())));
  }

  void _back() {
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      onClose();
      return;
    }

    unawaited(navigator.maybePop());
  }
}
