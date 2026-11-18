import 'dart:math' as math;

import 'package:feature_kit/layout/pane_widths.dart';
import 'package:feature_kit/layout/screen_size_context.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How wide a page's content may get on a large view.
enum ContentWidth {
  /// Lists and forms: [PaneWidths.content].
  page(PaneWidths.content),

  /// Pairing and empty states: [PaneWidths.narrowContent].
  narrow(PaneWidths.narrowContent),

  /// Takes all the room, such as a conversation or a mirrored screen.
  fill(double.infinity);

  const ContentWidth(this.max);

  final double max;
}

/// Keeps [child] from stretching across a large view: from
/// [ScreenSize.large] up it is centred under a maximum width; below, it
/// gets all the room. The widget tree is the same at every size, only the
/// margins change, so state, scroll position and focus survive a resize.
class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({super.key, required this.child, this.width = .page});

  final Widget child;
  final ContentWidth width;

  /// The room to leave on each side of content that is [width] wide at
  /// most, in [available] pixels on a [screenSize] view.
  static double marginFor(
    ScreenSize screenSize,
    double available,
    ContentWidth width,
  ) {
    if (screenSize < ScreenSize.large || !available.isFinite) {
      return 0;
    }

    return math.max(0, (available - width.max) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: marginFor(screenSize, constraints.maxWidth, width),
        ),
        child: child,
      ),
    );
  }
}
