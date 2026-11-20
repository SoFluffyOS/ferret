import 'package:fake_async/fake_async.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/services/services.dart';

void main() {
  const size = Size(400, 800);
  late List<MirrorPointer> sent;
  late TouchMouse touch;
  var held = 0;

  setUp(() {
    sent = [];
    held = 0;
    touch = TouchMouse(send: sent.add, pointsPerPixel: 2, onHeld: () => held++);
  });

  tearDown(() => touch.dispose());

  List<(PointerPhase, int)> steps() => [
    for (final pointer in sent) (pointer.phase, pointer.buttons),
  ];

  test('a tap moves the pointer there and clicks', () {
    touch
      ..down(1, const Offset(200, 400), size)
      ..up(1, const Offset(201, 401), size);

    expect(steps(), [
      (PointerPhase.hover, 0),
      (PointerPhase.down, 1),
      (PointerPhase.up, 1),
    ]);
    expect(sent[1].x, 0.5);
    expect(sent[1].y, 0.5);
  });

  test('a drag holds the button from where it started', () {
    touch
      ..down(1, const Offset(100, 100), size)
      ..move(1, const Offset(103, 100), size)
      ..move(1, const Offset(140, 100), size)
      ..move(1, const Offset(200, 100), size)
      ..up(1, const Offset(200, 100), size);

    expect(steps(), [
      (PointerPhase.hover, 0),
      (PointerPhase.down, 1),
      (PointerPhase.move, 1),
      (PointerPhase.move, 1),
      (PointerPhase.up, 1),
    ]);
    expect(sent[1].x, 0.25, reason: 'pressed where the finger landed');
    expect(sent.last.x, 0.5);
  });

  test('holding still right-clicks, once', () {
    fakeAsync((async) {
      touch.down(1, const Offset(100, 100), size);
      async.elapse(const Duration(milliseconds: 600));
      touch
        ..move(1, const Offset(180, 100), size)
        ..up(1, const Offset(180, 100), size);

      expect(steps(), [
        (PointerPhase.hover, 0),
        (PointerPhase.down, 2),
        (PointerPhase.up, 2),
      ]);
      expect(held, 1);
    });
  });

  test('two fingers scroll, the content following them', () {
    touch
      ..down(1, const Offset(100, 400), size)
      ..down(2, const Offset(200, 400), size)
      ..move(1, const Offset(100, 350), size)
      ..move(2, const Offset(200, 350), size)
      ..up(1, const Offset(100, 350), size)
      ..up(2, const Offset(200, 350), size);

    final scrolls = [
      for (final pointer in sent)
        if (pointer.phase == .scroll) pointer,
    ];
    expect(scrolls, hasLength(2));
    final down = scrolls.fold(0.0, (sum, pointer) => sum + pointer.scrollY);
    // 50 pixels up at 2 points a pixel is 100 points: 2 notches down.
    expect(down, closeTo(2, 0.0001));
    expect(sent.where((pointer) => pointer.phase == .down), isEmpty);
  });

  test('a cancelled drag lets go of the button', () {
    touch
      ..down(1, const Offset(100, 100), size)
      ..move(1, const Offset(200, 100), size)
      ..cancel(1);

    expect(steps().last, (PointerPhase.up, 1));

    sent.clear();
    touch
      ..down(3, const Offset(100, 100), size)
      ..up(3, const Offset(100, 100), size);
    expect(steps(), [
      (PointerPhase.hover, 0),
      (PointerPhase.down, 1),
      (PointerPhase.up, 1),
    ]);
  });
}
