import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';

/// Turns the mouse, the trackpad and the keyboard on a mirrored picture
/// into what its device understands: a click is a touch, a right-click is
/// Back, a middle-click is Home, the wheel and two fingers scroll, and
/// typing types. Positions are fractions of [child], so they hold whatever
/// size the picture is drawn at. A computer's extra display takes the
/// mouse as a mouse instead: hovering moves its pointer, which it draws
/// itself, and every button clicks. Fingers on it work as that mouse too
/// ([TouchMouse]): tap to click, drag, hold to right-click, two fingers
/// to scroll.
class MirrorInput extends StatefulWidget {
  const MirrorInput({
    super.key,
    required this.child,
    required this.abilities,
    this.onAction,
    this.onViewOnlyTap,
    this.onEscape,
    this.focusNode,
    this.touchPointsPerPixel = 1,
  });

  /// One mouse wheel notch, in the pixels Flutter reports for it.
  static const pixelsPerNotch = 50.0;

  final Widget child;

  /// What the device being shown takes. Empty is view only.
  final Set<ControlAbility> abilities;

  final ValueChanged<InputAction>? onAction;

  /// A click on a picture that takes none, to say so.
  final VoidCallback? onViewOnlyTap;

  /// Esc on a computer's display, where it leaves full screen instead of
  /// reaching that computer. Null lets Esc through.
  final VoidCallback? onEscape;

  final FocusNode? focusNode;

  /// Points of a computer's display per pixel a finger moves, for
  /// scrolling with two fingers.
  final double touchPointsPerPixel;

  @override
  State<MirrorInput> createState() => _MirrorInputState();
}

class _MirrorInputState extends State<MirrorInput> {
  /// Pointers whose press was a device button, not a touch: the rest of
  /// their gesture is swallowed.
  final Set<int> _buttonPresses = {};

  /// Keys whose press went as text: their release has nothing to send.
  final Set<PhysicalKeyboardKey> _typedKeys = {};

  /// The mouse buttons each pointer pressed, for its moves and release.
  final Map<int, int> _pressed = {};

  late final TouchMouse _touch = TouchMouse(
    send: (pointer) => _send(SendPointer(pointer)),
    pointsPerPixel: widget.touchPointsPerPixel,
    onHeld: () => unawaited(HapticFeedback.mediumImpact()),
  );

  bool get _isMouse => widget.abilities.contains(ControlAbility.mouse);

  bool get _canPoint => widget.abilities.contains(ControlAbility.pointer);

  bool get _canPress => widget.abilities.contains(ControlAbility.buttons);

  KeyModifier get _shortcut => switch (defaultTargetPlatform) {
    .macOS || .iOS => .meta,
    _ => .control,
  };

  @override
  void didUpdateWidget(MirrorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _touch.pointsPerPixel = widget.touchPointsPerPixel;
  }

  @override
  void dispose() {
    _touch.dispose();
    super.dispose();
  }

  /// A finger on a computer's display, which takes it as its mouse.
  bool _isFinger(PointerEvent event) =>
      _isMouse &&
      (event.kind == PointerDeviceKind.touch ||
          event.kind == PointerDeviceKind.stylus);

  @override
  Widget build(BuildContext context) {
    if (widget.abilities.isEmpty) {
      return Focus(
        focusNode: widget.focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Listener(
          behavior: .opaque,
          onPointerDown: (_) => widget.onViewOnlyTap?.call(),
          child: widget.child,
        ),
      );
    }

    final pointing = switch (_canPoint) {
      false => widget.child,
      true => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          final listener = Listener(
            behavior: .opaque,
            onPointerDown: (event) => _onDown(event, size),
            onPointerMove: (event) => _onTouch(.move, event, size),
            onPointerUp: (event) => _onTouch(.up, event, size),
            onPointerCancel: (event) => _onTouch(.cancel, event, size),
            onPointerHover: (event) => _onHover(event, size),
            onPointerSignal: (event) => _onSignal(event, size),
            onPointerPanZoomUpdate: (event) => _onPan(event, size),
            child: widget.child,
          );
          if (!_isMouse) {
            return listener;
          }

          // The display draws its own pointer into the picture.
          return MouseRegion(cursor: SystemMouseCursors.none, child: listener);
        },
      ),
    };

    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: pointing,
    );
  }

  void _send(InputAction action) => widget.onAction?.call(action);

  void _onDown(PointerDownEvent event, Size size) {
    if (_isFinger(event)) {
      _touch.down(event.pointer, event.localPosition, size);
      return;
    }

    final button = _buttonOf(event);
    if (button != null) {
      _buttonPresses.add(event.pointer);
      _send(PressButton(button));
      return;
    }

    _pressed[event.pointer] = event.buttons;
    _send(SendPointer(_pointerOf(.down, event, size)));
  }

  void _onHover(PointerHoverEvent event, Size size) {
    if (!_isMouse) {
      return;
    }

    _send(SendPointer(_pointerOf(.hover, event, size)));
  }

  void _onTouch(PointerPhase phase, PointerEvent event, Size size) {
    if (_isFinger(event)) {
      switch (phase) {
        case .move:
          _touch.move(event.pointer, event.localPosition, size);
        case .up:
          _touch.up(event.pointer, event.localPosition, size);
        case .cancel || .down || .hover || .scroll:
          _touch.cancel(event.pointer);
      }

      return;
    }

    final wasButton = _buttonPresses.contains(event.pointer);
    if (wasButton && phase != .move) {
      _buttonPresses.remove(event.pointer);
    }

    if (wasButton) {
      return;
    }

    _send(SendPointer(_pointerOf(phase, event, size)));
    if (phase != .move) {
      _pressed.remove(event.pointer);
    }
  }

  void _onSignal(PointerSignalEvent event, Size size) {
    if (event is! PointerScrollEvent) {
      return;
    }

    _scroll(event, event.scrollDelta, size);
  }

  /// Two fingers on a trackpad arrive as a pan, not as a wheel: the
  /// content follows the fingers, so the scroll goes the other way.
  void _onPan(PointerPanZoomUpdateEvent event, Size size) {
    final delta = event.localPanDelta;
    if (delta == Offset.zero) {
      return;
    }

    _scroll(event, -delta, size);
  }

  void _scroll(PointerEvent event, Offset pixels, Size size) {
    final notches = pixels / MirrorInput.pixelsPerNotch;
    _send(
      SendPointer(
        MirrorPointer(
          phase: .scroll,
          x: _fraction(event.localPosition.dx, size.width),
          y: _fraction(event.localPosition.dy, size.height),
          buttons: 0,
          scrollX: notches.dx,
          scrollY: notches.dy,
        ),
      ),
    );
  }

  /// The device button a mouse button stands for: right is Back, middle
  /// is Home, as in every tool that mirrors a phone.
  DeviceButton? _buttonOf(PointerDownEvent event) {
    if (!_canPress || event.kind != PointerDeviceKind.mouse) {
      return null;
    }

    if (event.buttons & kSecondaryMouseButton != 0) {
      return .back;
    }

    if (event.buttons & kMiddleMouseButton != 0) {
      return .home;
    }

    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent && _typedKeys.remove(event.physicalKey)) {
      return .handled;
    }

    final onEscape = widget.onEscape;
    final leaves =
        onEscape != null &&
        _isMouse &&
        event.logicalKey == LogicalKeyboardKey.escape;
    if (leaves && event is KeyDownEvent) {
      onEscape();
    }

    if (leaves) {
      return .handled;
    }

    final action = MirrorKeys.actionOf(
      event,
      modifiers: MirrorKeys.modifiersOf(HardwareKeyboard.instance),
      abilities: widget.abilities,
      shortcut: _shortcut,
    );
    if (action == null) {
      return .ignored;
    }

    if (action is SendText || action is PasteText) {
      _typedKeys.add(event.physicalKey);
    }

    _send(action);
    return .handled;
  }

  MirrorPointer _pointerOf(PointerPhase phase, PointerEvent event, Size size) =>
      MirrorPointer(
        phase: phase,
        x: _fraction(event.localPosition.dx, size.width),
        y: _fraction(event.localPosition.dy, size.height),
        pointerId: event.device,
        buttons: switch (_isMouse) {
          true => _pressed[event.pointer] ?? 0,
          false => kPrimaryButton,
        },
      );

  double _fraction(double position, double length) {
    if (length <= 0) {
      return 0;
    }

    return (position / length).clamp(0.0, 1.0);
  }
}
