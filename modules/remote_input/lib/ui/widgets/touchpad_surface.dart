import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_input/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The touchpad: a filled panel that reads raw touches, so several fingers
/// work at once, and hands them to [TouchpadGestures]. It fills the space
/// its parent gives it.
///
/// It claims every touch that starts on it, so a scrolling parent, a
/// swipe-back or the iOS bounce never move the page under the finger. A
/// touch also puts the on-screen keyboard away.
class TouchpadSurface extends StatefulWidget {
  const TouchpadSurface({super.key, required this.sink, required this.hint});

  final TouchpadSink sink;
  final String hint;

  @override
  State<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends State<TouchpadSurface> {
  late TouchpadGestures _gestures = TouchpadGestures(widget.sink);

  @override
  void didUpdateWidget(TouchpadSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sink != widget.sink) {
      _gestures.dispose();
      _gestures = TouchpadGestures(widget.sink);
    }
  }

  @override
  void dispose() {
    _gestures.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return RawGestureDetector(
      behavior: .opaque,
      gestures: {
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (_) {},
            ),
      },
      child: Listener(
        behavior: .opaque,
        onPointerDown: (event) {
          FocusManager.instance.primaryFocus?.unfocus();
          _gestures.down(event.pointer, event.localPosition, event.timeStamp);
        },
        onPointerMove: (event) => _gestures.moveTo(
          event.pointer,
          event.localPosition,
          event.timeStamp,
        ),
        onPointerUp: (event) => _gestures.up(event.pointer, event.timeStamp),
        onPointerCancel: (event) => _gestures.cancel(event.pointer),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: Corners.shape(Corners.panel),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(Spacing.d24),
              child: Text(
                widget.hint,
                textAlign: .center,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
