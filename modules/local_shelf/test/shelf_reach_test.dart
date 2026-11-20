import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';

import 'shake_detector_test.dart' show zigzag;

/// A 1440 × 900 screen with a 25 pt menu bar and the Dock hidden.
const _screen = SystemScreen(
  frame: Rect.fromLTWH(0, 0, 1440, 900),
  visible: Rect.fromLTWH(0, 0, 1440, 875),
);

/// The same screen with the Dock on its right side.
const _dockRight = SystemScreen(
  frame: Rect.fromLTWH(0, 0, 1440, 900),
  visible: Rect.fromLTWH(0, 0, 1380, 875),
);

const _size = Size(320, 152);

class _Panel {
  final List<(Rect, PanelMotion)> shown = [];
  int hidden = 0;
  bool isShown = false;
}

void main() {
  late ShelfReachOptions options;
  late _Panel panel;

  ShelfReach reachIn(FakeAsync async) => ShelfReach(
    options: () => options,
    panelSize: _size,
    now: () => async.elapsed,
    show: (frame, motion) async {
      panel
        ..shown.add((frame, motion))
        ..isShown = true;
      return true;
    },
    hide: () async {
      panel
        ..hidden += 1
        ..isShown = false;
    },
  );

  void start(
    ShelfReach reach,
    Offset at, {
    SystemDragKind kind = .files,
    String? app,
    bool fn = false,
    SystemScreen? screen,
  }) => reach.handle(
    SystemDragStarted(
      kind: kind,
      position: at,
      screen: screen ?? _screen,
      sourceApp: app,
      fn: fn,
    ),
  );

  void move(
    ShelfReach reach,
    Offset to, {
    bool fn = false,
    bool shift = false,
    SystemScreen? screen,
  }) => reach.handle(
    SystemDragMoved(
      position: to,
      screen: screen ?? _screen,
      fn: fn,
      shift: shift,
    ),
  );

  /// Moves in 20 pt steps every 16 ms, as a steady drag does.
  void glide(
    ShelfReach reach,
    FakeAsync async,
    Offset from,
    Offset to, {
    SystemScreen? screen,
  }) {
    final steps = ((to - from).distance / 20).ceil();
    for (var index = 1; index <= steps; index++) {
      async.elapse(const Duration(milliseconds: 16));
      move(reach, Offset.lerp(from, to, index / steps)!, screen: screen);
    }
  }

  void shake(ShelfReach reach, FakeAsync async, Offset at) {
    var last = Duration.zero;
    for (final (time, position) in zigzag(strokes: 4, length: 24, start: at)) {
      async.elapse(time - last);
      last = time;
      move(reach, position);
    }
  }

  setUp(() {
    options = const ShelfReachOptions();
    panel = _Panel();
  });

  test('the defaults: a plain drag to the edge brings nothing', () {
    fakeAsync((async) {
      final reach = reachIn(async);
      start(reach, const Offset(400, 400));
      glide(reach, async, const Offset(400, 400), const Offset(1430, 400));

      expect(panel.shown, isEmpty);
      expect(reach.place, ShelfPanelPlace.hidden);
    });
  });

  group('box on drag', () {
    setUp(() => options = const ShelfReachOptions(boxOnDrag: true));

    test('slides in at the middle of the right edge near the edge', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300));
        glide(reach, async, const Offset(400, 300), const Offset(1300, 300));
        expect(panel.shown, isEmpty, reason: 'not near the edge yet');

        glide(reach, async, const Offset(1300, 300), const Offset(1420, 300));

        final (frame, motion) = panel.shown.single;
        expect(motion, PanelMotion.fromRight);
        expect(
          frame,
          const Rect.fromLTWH(1440 - 8 - 320, 437.5 - 76, 320, 152),
        );
        expect(reach.place, ShelfPanelPlace.edge);
      });
    });

    test('comes in from the left when the Dock is on the right', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300), screen: _dockRight);
        glide(
          reach,
          async,
          const Offset(400, 300),
          const Offset(1430, 300),
          screen: _dockRight,
        );
        expect(panel.shown, isEmpty);

        glide(
          reach,
          async,
          const Offset(1430, 300),
          const Offset(10, 300),
          screen: _dockRight,
        );

        final (frame, motion) = panel.shown.single;
        expect(motion, PanelMotion.fromLeft);
        expect(frame.left, 8);
      });
    });

    test('a small drag right at the edge passes by', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(1410, 300));
        glide(reach, async, const Offset(1410, 300), const Offset(1430, 310));

        expect(panel.shown, isEmpty);
      });
    });

    test('As soon as I drag shows it once the drag got going', () {
      options = const ShelfReachOptions(boxOnDrag: true, boxShows: .onDrag);
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300));
        move(reach, const Offset(420, 300));
        expect(panel.shown, isEmpty);

        move(reach, const Offset(450, 300));
        expect(panel.shown.single.$2, PanelMotion.fromRight);
      });
    });

    test('text, links and drags from ignored apps never bring it', () {
      options = const ShelfReachOptions(
        boxOnDrag: true,
        boxShows: .onDrag,
        ignoredApps: [IgnoredApp(id: 'com.apple.Safari', name: 'Safari')],
      );
      fakeAsync((async) {
        final reach = reachIn(async);
        for (final kind in [SystemDragKind.text, SystemDragKind.link]) {
          start(reach, const Offset(400, 300), kind: kind);
          glide(reach, async, const Offset(400, 300), const Offset(1430, 300));
          reach.handle(const SystemDragEnded());
        }

        start(reach, const Offset(400, 300), app: 'com.apple.Safari');
        glide(reach, async, const Offset(400, 300), const Offset(1430, 300));

        expect(panel.shown, isEmpty);
      });
    });

    test('fn skips it for one drag, and hides it when pressed later', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300), fn: true);
        glide(reach, async, const Offset(400, 300), const Offset(1430, 300));
        reach.handle(const SystemDragEnded());
        expect(panel.shown, isEmpty);

        start(reach, const Offset(400, 300));
        glide(reach, async, const Offset(400, 300), const Offset(1430, 300));
        expect(panel.shown, hasLength(1));

        move(reach, const Offset(1431, 300), fn: true);
        expect(panel.hidden, 1);
        expect(reach.place, ShelfPanelPlace.hidden);
        move(reach, const Offset(1432, 300));
        expect(panel.shown, hasLength(1), reason: 'skipped for this drag');
      });
    });

    test('slides away when the drag reaches the menu bar', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300));
        glide(reach, async, const Offset(400, 300), const Offset(1430, 300));
        expect(reach.place, ShelfPanelPlace.edge);

        glide(reach, async, const Offset(1430, 300), const Offset(1300, 890));
        expect(panel.hidden, 1);

        glide(reach, async, const Offset(1300, 890), const Offset(1430, 500));
        expect(panel.shown, hasLength(1), reason: 'not back in this drag');
      });
    });
  });

  group('after the drag', () {
    setUp(
      () =>
          options = const ShelfReachOptions(boxOnDrag: true, boxShows: .onDrag),
    );

    test('nothing dropped: it goes a moment after the drag ends', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300));
        move(reach, const Offset(500, 300));
        reach.handle(const SystemDragEnded());

        async.elapse(const Duration(milliseconds: 200));
        expect(panel.hidden, 0);
        async.elapse(const Duration(milliseconds: 200));
        expect(panel.hidden, 1);
        expect(reach.place, ShelfPanelPlace.hidden);
      });
    });

    test('something dropped: it stays long enough to see it land', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300));
        move(reach, const Offset(500, 300));
        reach.handle(const SystemDragEnded());
        async.elapse(const Duration(milliseconds: 50));
        reach.dropped();

        async.elapse(const Duration(milliseconds: 1000));
        expect(panel.hidden, 0);
        async.elapse(const Duration(milliseconds: 600));
        expect(panel.hidden, 1);
      });
    });

    test('it stays while the pointer rests on it', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(400, 300));
        move(reach, const Offset(500, 300));
        reach
          ..handle(const SystemDragEnded())
          ..hovering(over: true);

        async.elapse(const Duration(seconds: 5));
        expect(panel.hidden, 0);

        reach.hovering(over: false);
        async.elapse(const Duration(milliseconds: 1600));
        expect(panel.hidden, 1);
      });
    });
  });

  group('shake', () {
    test('brings it beside the pointer, never under it', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(600, 400));
        shake(reach, async, const Offset(600, 400));

        final (frame, motion) = panel.shown.single;
        expect(motion, PanelMotion.inPlace);
        expect(reach.place, ShelfPanelPlace.pointer);
        expect(frame.left, greaterThan(624));
        expect(frame.contains(const Offset(624, 400)), isFalse);
        expect(frame.center.dy, closeTo(400, 1));
      });
    });

    test('near the right edge it opens on the pointer\'s left', () {
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(1300, 400));
        shake(reach, async, const Offset(1300, 400));

        final frame = panel.shown.single.$1;
        expect(frame.right, lessThan(1300));
      });
    });

    test('works for text and links too, but not from ignored apps', () {
      options = const ShelfReachOptions(
        ignoredApps: [IgnoredApp(id: 'com.figma.Desktop', name: 'Figma')],
      );
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(600, 400), app: 'com.figma.Desktop');
        shake(reach, async, const Offset(600, 400));
        reach.handle(const SystemDragEnded());
        expect(panel.shown, isEmpty);

        start(reach, const Offset(600, 400), kind: .link);
        shake(reach, async, const Offset(600, 400));
        expect(panel.shown, hasLength(1));
      });
    });

    test('moves the edge box to the pointer: one panel only', () {
      options = const ShelfReachOptions(boxOnDrag: true, boxShows: .onDrag);
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(600, 400));
        move(reach, const Offset(650, 400));
        expect(reach.place, ShelfPanelPlace.edge);

        shake(reach, async, const Offset(650, 400));

        expect(panel.shown, hasLength(2));
        expect(panel.shown.last.$2, PanelMotion.inPlace);
        expect(panel.hidden, 0);
        expect(reach.place, ShelfPanelPlace.pointer);
      });
    });

    test('off in Settings, a shake does nothing', () {
      options = const ShelfReachOptions(shake: false);
      fakeAsync((async) {
        final reach = reachIn(async);
        start(reach, const Offset(600, 400));
        shake(reach, async, const Offset(600, 400));

        expect(panel.shown, isEmpty);
      });
    });
  });

  test('holding ⇧ brings it when that is turned on', () {
    fakeAsync((async) {
      final reach = reachIn(async);
      start(reach, const Offset(600, 400));
      move(reach, const Offset(610, 400), shift: true);
      expect(panel.shown, isEmpty);

      options = const ShelfReachOptions(shiftSummons: true);
      move(reach, const Offset(620, 400), shift: true);
      expect(panel.shown.single.$2, PanelMotion.inPlace);
    });
  });

  test('settings that turn it all off take the panel away', () {
    options = const ShelfReachOptions(boxOnDrag: true, boxShows: .onDrag);
    fakeAsync((async) {
      final reach = reachIn(async)
        ..handle(
          const SystemDragStarted(
            kind: .files,
            position: Offset(400, 300),
            screen: _screen,
          ),
        );
      move(reach, const Offset(500, 300));
      reach.dismiss();

      expect(panel.hidden, 1);
      expect(reach.place, ShelfPanelPlace.hidden);
    });
  });
}
