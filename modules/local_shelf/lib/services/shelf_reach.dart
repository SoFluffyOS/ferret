import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:local_shelf/models/models.dart';

/// Where the floating shelf is.
enum ShelfPanelPlace {
  hidden,

  /// Middle of a screen's side edge: it showed up by itself.
  edge,

  /// Next to the pointer: a shake or ⇧ brought it.
  pointer,
}

/// Brings the shelf to a drag going on in another app, and takes it away
/// again: by itself at the screen's edge (when turned on), next to the
/// pointer on a shake or with ⇧, never for apps on the ignore list. One
/// panel only: a shake moves the edge box to the pointer. It slides away
/// when the drag reaches the menu bar, where the icon's popover takes
/// over, and after the drag ends: at once when nothing landed on it, after
/// a moment when something did, never while the pointer rests on it.
///
/// Positions are the system's screen points, y going up, as
/// [SystemScreen] has them.
class ShelfReach {
  ShelfReach({
    required ShelfReachOptions Function() options,
    required this.panelSize,
    required Future<bool> Function(Rect frame, PanelMotion motion) show,
    required Future<void> Function() hide,
    Duration Function()? now,
    this.edgeZone = 48,
    this.moveThreshold = 40,
    this.margin = 8,
    this.pointerGap = 24,
    this.endHide = const Duration(milliseconds: 300),
    this.dropHold = const Duration(milliseconds: 1500),
    this.shakeCooldown = const Duration(seconds: 1),
  }) : _options = options,
       _show = show,
       _hide = hide,
       _now = now ?? _stopwatchNow();

  final ShelfReachOptions Function() _options;
  final Future<bool> Function(Rect frame, PanelMotion motion) _show;
  final Future<void> Function() _hide;
  final Duration Function() _now;

  /// The panel's size, in points.
  Size panelSize;

  /// How close to a screen's side the pointer must come for the box.
  final double edgeZone;

  /// How far a drag must go before the box comes, so a small drag inside
  /// an app (a tab, a list row) passes by.
  final double moveThreshold;

  /// Between the panel and the screen's edge.
  final double margin;

  /// Between the pointer and the panel next to it, so it is never under
  /// the pointer.
  final double pointerGap;

  /// How long the panel stays after a drag ends with nothing dropped on it.
  final Duration endHide;

  /// How long it stays after something landed on it.
  final Duration dropHold;

  /// After one shake, how long until another counts.
  final Duration shakeCooldown;

  final ShakeDetector _shake = ShakeDetector();
  ShelfPanelPlace _place = .hidden;
  Timer? _hideTimer;
  bool _dragging = false;
  bool _ignored = false;
  bool _skipsEdge = false;
  bool _leftForMenuBar = false;
  bool _hovered = false;
  bool _dropped = false;
  SystemDragKind _kind = .files;
  Offset _start = Offset.zero;
  Duration? _lastSummon;

  ShelfPanelPlace get place => _place;

  bool get isDragging => _dragging;

  static Duration Function() _stopwatchNow() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  void handle(SystemDragEvent event) {
    switch (event) {
      case SystemDragStarted():
        _started(event);
      case SystemDragMoved(
        :final position,
        :final screen,
        :final fn,
        :final shift,
      ):
        _moved(position, screen, fn: fn, shift: shift);
      case SystemDragEnded():
        _ended();
    }
  }

  /// Something landed on the panel.
  void dropped() {
    _dropped = true;
    if (_place == .hidden || _dragging) {
      return;
    }

    _hideAfter(dropHold);
  }

  /// The pointer rests on the panel, or left it.
  void hovering({required bool over}) {
    _hovered = over;
    if (over) {
      _hideTimer?.cancel();
      return;
    }

    if (_place != .hidden && !_dragging) {
      _hideAfter(dropHold);
    }
  }

  /// Takes the panel away now, such as when the settings turned it off.
  void dismiss() {
    _hideTimer?.cancel();
    if (_place == .hidden) {
      return;
    }

    _place = .hidden;
    unawaited(_hide());
  }

  void dispose() => _hideTimer?.cancel();

  void _started(SystemDragStarted event) {
    final options = _options();
    _hideTimer?.cancel();
    _dragging = true;
    _kind = event.kind;
    _start = event.position;
    _ignored = options.ignores(event.sourceApp);
    _skipsEdge = event.fn;
    _leftForMenuBar = false;
    _dropped = false;
    _shake
      ..sensitivity = options.sensitivity
      ..reset();
    _moved(event.position, event.screen, fn: event.fn, shift: event.shift);
  }

  void _moved(
    Offset position,
    SystemScreen screen, {
    required bool fn,
    required bool shift,
  }) {
    if (!_dragging || _ignored) {
      return;
    }

    final options = _options();
    if (fn) {
      _skipsEdge = true;
      if (_place == .edge) {
        dismiss();
      }
    }

    if (screen.isInMenuBar(position)) {
      _leftForMenuBar = true;
      dismiss();
      _shake.reset();
      return;
    }

    final now = _now();
    final shook = options.shake && _shake.add(position, now);
    final cooledDown = switch (_lastSummon) {
      null => true,
      final last => now - last >= shakeCooldown,
    };
    final summoned = shook || (options.shiftSummons && shift);
    if (summoned && cooledDown && _place != .pointer) {
      _lastSummon = now;
      _showAt(_besidePointer(position, screen.visible), .inPlace, .pointer);
      return;
    }

    final wantsEdge =
        options.boxOnDrag &&
        _kind == .files &&
        !_skipsEdge &&
        !_leftForMenuBar &&
        _place == .hidden &&
        (position - _start).distance >= moveThreshold;
    if (!wantsEdge) {
      return;
    }

    final side = _sideOf(screen);
    final nearEdge = switch (side) {
      .fromLeft => position.dx - screen.frame.left <= edgeZone,
      _ => screen.frame.right - position.dx <= edgeZone,
    };
    if (options.boxShows == .onDrag || nearEdge) {
      _showAt(_atEdge(screen, side), side, .edge);
    }
  }

  void _ended() {
    if (!_dragging) {
      return;
    }

    _dragging = false;
    _shake.reset();
    if (_place == .hidden) {
      return;
    }

    _hideAfter(switch (_dropped) {
      true => dropHold,
      false => endHide,
    });
  }

  void _hideAfter(Duration delay) {
    _hideTimer?.cancel();
    if (_hovered) {
      return;
    }

    _hideTimer = Timer(delay, dismiss);
  }

  void _showAt(Rect frame, PanelMotion motion, ShelfPanelPlace place) {
    _hideTimer?.cancel();
    _place = place;
    unawaited(_show(frame, motion));
  }

  /// The right edge, unless the Dock sits there.
  PanelMotion _sideOf(SystemScreen screen) =>
      switch (screen.visible.right < screen.frame.right - 1) {
        true => .fromLeft,
        false => .fromRight,
      };

  /// The middle of [side] of the screen, inside what the Dock and the menu
  /// bar leave.
  Rect _atEdge(SystemScreen screen, PanelMotion side) {
    final visible = screen.visible;
    final x = switch (side) {
      .fromLeft => visible.left + margin,
      _ => visible.right - margin - panelSize.width,
    };
    final y = visible.center.dy - panelSize.height / 2;
    return Rect.fromLTWH(x, y, panelSize.width, panelSize.height);
  }

  /// Beside the pointer, on whichever side has room, never under it.
  Rect _besidePointer(Offset pointer, Rect visible) {
    final width = panelSize.width;
    final height = panelSize.height;
    var x = pointer.dx + pointerGap;
    if (x + width > visible.right - margin) {
      x = pointer.dx - pointerGap - width;
    }

    final lowest = visible.top + margin;
    final highest = visible.bottom - margin - height;
    final y = (pointer.dy - height / 2).clamp(
      lowest,
      highest < lowest ? lowest : highest,
    );
    return Rect.fromLTWH(x, y, width, height);
  }
}
