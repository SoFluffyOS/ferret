import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/services/services.dart';

/// The first feature's bar along the bottom of the menubar popover, such
/// as the shelf. Nothing where the view is a window with a device list.
class PopoverBarFrame extends StatelessWidget {
  const PopoverBarFrame({super.key});

  @override
  Widget build(BuildContext context) {
    if (WindowLayout.splits(context)) {
      return const SizedBox.shrink();
    }

    final scope = ShellScope.of(context);
    for (final feature in scope.features) {
      final bar = feature.buildPopoverBar(context, scope.featureContext);
      if (bar != null) {
        return bar;
      }
    }

    return const SizedBox.shrink();
  }
}
