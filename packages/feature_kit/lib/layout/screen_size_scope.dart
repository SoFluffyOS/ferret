import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Gives everything below it the [ScreenSize] of the view it is drawn in,
/// read with `context.screenSize`. One per view: on a Mac the popover stays
/// small while the desktop window is large.
class ScreenSizeScope extends StatefulWidget {
  const ScreenSizeScope({super.key, required this.child});

  final Widget child;

  @override
  State<ScreenSizeScope> createState() => _ScreenSizeScopeState();
}

class _ScreenSizeScopeState extends State<ScreenSizeScope> {
  final ScreenSizeNotifier _notifier = ScreenSizeNotifier();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = ScreenSize.of(context);
    if (screenSize == _notifier.screenSize) {
      return;
    }

    _notifier.updateScreenSize(screenSize);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(value: _notifier, child: widget.child);
  }
}
