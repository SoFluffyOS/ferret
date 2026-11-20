import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/services/services.dart';

/// The first feature's bar along the bottom of the Mac's menubar popover,
/// such as the shelf. Nothing in a window or on a phone.
class PopoverBarFrame extends StatelessWidget {
  const PopoverBarFrame({super.key});

  /// The bar the popover shows under its pages, or null when there is none.
  static Widget? barFor(BuildContext context) {
    final isMainView =
        View.of(context).viewId ==
        WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
    if (defaultTargetPlatform != .macOS ||
        !isMainView ||
        WindowLayout.splits(context)) {
      return null;
    }

    final scope = ShellScope.of(context);
    for (final feature in scope.features) {
      final bar = feature.buildPopoverBar(context, scope.featureContext);
      if (bar != null) {
        return bar;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) =>
      barFor(context) ?? const SizedBox.shrink();
}
