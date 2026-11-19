import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The slim bar along the top of the picture's own window: the title bar's
/// own buttons at the start, the device's name, and [trailing] controls at
/// the end. The window keeps this room above the picture, so nothing here
/// ever covers it. A press anywhere but a control moves the window.
class MirrorWindowBar extends StatelessWidget {
  const MirrorWindowBar({
    super.key,
    required this.title,
    this.onDragStart,
    this.trailing,
  });

  /// As tall as the Mac's title bar, so its buttons sit centred in it.
  static double get height => Spacing.d32;

  /// The room the title bar's close, minimize and zoom buttons take.
  static double get buttonsWidth => Spacing.d80;

  final String title;
  final VoidCallback? onDragStart;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      behavior: .opaque,
      onPanStart: (_) => onDragStart?.call(),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: buttonsWidth,
            end: Spacing.d4,
          ),
          // The controls get the room they need first; the name takes
          // what is left.
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.fluffyTheme.typography.caption1.copyWith(
                      color: palette.mutedText,
                      fontWeight: .w600,
                    ),
                  ),
                ),
                if (trailing case final trailing?)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
