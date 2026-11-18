import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/services/services.dart';

/// Turns clicks, scrolling and typing on a mirrored picture into what its
/// device understands. Positions are fractions of [child], so they hold
/// whatever size the picture is drawn at.
class MirrorInput extends StatelessWidget {
  const MirrorInput({
    super.key,
    required this.child,
    this.onPointer,
    this.onKey,
  });

  /// One mouse wheel notch, in the pixels Flutter reports for it.
  static const _pixelsPerNotch = 50.0;

  final Widget child;

  /// Null leaves clicks and scrolling on this computer.
  final ValueChanged<MirrorPointer>? onPointer;

  /// Null leaves typing on this computer.
  final ValueChanged<MirrorKey>? onKey;

  @override
  Widget build(BuildContext context) {
    final pointing = switch (onPointer) {
      null => child,
      final send => LayoutBuilder(
        builder: (context, constraints) => Listener(
          behavior: .opaque,
          onPointerDown: (event) =>
              send(_pointerOf(.down, event, constraints.biggest)),
          onPointerMove: (event) =>
              send(_pointerOf(.move, event, constraints.biggest)),
          onPointerUp: (event) =>
              send(_pointerOf(.up, event, constraints.biggest)),
          onPointerCancel: (event) =>
              send(_pointerOf(.cancel, event, constraints.biggest)),
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              send(_pointerOf(.scroll, event, constraints.biggest));
            }
          },
          child: child,
        ),
      ),
    };
    final sendKey = onKey;
    if (sendKey == null) {
      return pointing;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final key = MirrorKeys.keyOf(
          event,
          modifiers: MirrorKeys.modifiersOf(HardwareKeyboard.instance),
        );
        if (key == null) {
          return .ignored;
        }

        sendKey(key);
        return .handled;
      },
      child: pointing,
    );
  }

  MirrorPointer _pointerOf(PointerPhase phase, PointerEvent event, Size size) {
    final scroll = switch (event) {
      PointerScrollEvent(:final scrollDelta) => scrollDelta / _pixelsPerNotch,
      _ => Offset.zero,
    };

    return MirrorPointer(
      phase: phase,
      x: _fraction(event.localPosition.dx, size.width),
      y: _fraction(event.localPosition.dy, size.height),
      pointerId: event.device,
      buttons: event.buttons,
      scrollX: scroll.dx,
      scrollY: scroll.dy,
    );
  }

  double _fraction(double position, double length) {
    if (length <= 0) {
      return 0;
    }

    return (position / length).clamp(0.0, 1.0);
  }
}
