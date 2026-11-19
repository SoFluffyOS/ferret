import 'package:flutter/widgets.dart';
import 'package:shell/ui/frames/sidebar_frame.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The device list, which slides out of the window when it is hidden and
/// back in when it is shown. Hidden, it takes no room and is out of the
/// keyboard's and the screen reader's reach.
class SlidingSidebar extends StatefulWidget {
  const SlidingSidebar({
    super.key,
    required this.isHidden,
    required this.width,
  });

  final bool isHidden;
  final double width;

  @override
  State<SlidingSidebar> createState() => _SlidingSidebarState();
}

class _SlidingSidebarState extends State<SlidingSidebar>
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
  void didUpdateWidget(SlidingSidebar oldWidget) {
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
