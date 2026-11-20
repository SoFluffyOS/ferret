import 'package:flutter/widgets.dart';

/// An [Overlay] around a view's pages and its footer bar, which sits
/// outside the pages' navigator: tooltips and menus in the bar then have
/// a place to show, over the whole view.
class FooterOverlay extends StatefulWidget {
  const FooterOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<FooterOverlay> createState() => _FooterOverlayState();
}

class _FooterOverlayState extends State<FooterOverlay> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => widget.child,
    opaque: true,
    maintainState: true,
  );

  @override
  void didUpdateWidget(FooterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
