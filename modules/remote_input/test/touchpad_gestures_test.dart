import 'package:fake_async/fake_async.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_input/remote_input.dart';

class RecordingSink implements TouchpadSink {
  final List<String> calls = [];
  double movedX = 0;
  double movedY = 0;
  double scrolledY = 0;

  @override
  void move(double dx, double dy, Duration elapsed) {
    movedX += dx;
    movedY += dy;
    if (calls.lastOrNull != 'move') {
      calls.add('move');
    }
  }

  @override
  void scroll(double dx, double dy) {
    scrolledY += dy;
    if (calls.lastOrNull != 'scroll') {
      calls.add('scroll');
    }
  }

  @override
  void click(PointerButton button) => calls.add('click ${button.name}');

  @override
  void press(PointerButton button) => calls.add('press ${button.name}');

  @override
  void release(PointerButton button) => calls.add('release ${button.name}');
}

void main() {
  late RecordingSink sink;
  late TouchpadGestures gestures;

  Duration ms(int milliseconds) => Duration(milliseconds: milliseconds);

  void run(void Function(FakeAsync async) body) => fakeAsync((async) {
    sink = RecordingSink();
    gestures = TouchpadGestures(sink);
    body(async);
    gestures.dispose();
  });

  test('one finger moves the pointer', () {
    run((_) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..moveTo(1, const Offset(10, 4), ms(16))
        ..moveTo(1, const Offset(30, 4), ms(32))
        ..up(1, ms(400));

      expect(sink.calls, ['move']);
      expect((sink.movedX, sink.movedY), (30.0, 4.0));
    });
  });

  test('a quick tap is a left click', () {
    run((_) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..moveTo(1, const Offset(2, 1), ms(40))
        ..up(1, ms(120));

      expect(sink.calls, ['move', 'click left']);
    });
  });

  test(
    'two taps are two clicks, which the computer reads as a double click',
    () {
      run((_) {
        gestures
          ..down(1, Offset.zero, ms(0))
          ..up(1, ms(80))
          ..down(2, Offset.zero, ms(200))
          ..up(2, ms(260));

        expect(sink.calls, ['click left', 'click left']);
      });
    },
  );

  test('two fingers scroll', () {
    run((_) {
      gestures
        ..down(1, const Offset(0, 100), ms(0))
        ..down(2, const Offset(40, 100), ms(5))
        ..moveTo(1, const Offset(0, 80), ms(20))
        ..moveTo(2, const Offset(40, 80), ms(20))
        ..up(1, ms(300))
        ..up(2, ms(300));

      expect(sink.calls, ['scroll']);
      expect(sink.scrolledY, -20);
    });
  });

  test('a two-finger tap is a right click', () {
    run((_) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..down(2, const Offset(40, 0), ms(10))
        ..up(1, ms(100))
        ..up(2, ms(110));

      expect(sink.calls, ['click right']);
    });
  });

  test('holding still is a right click, and lifting adds nothing', () {
    run((async) {
      gestures.down(1, Offset.zero, ms(0));
      async.elapse(ms(600));
      gestures.up(1, ms(600));

      expect(sink.calls, ['click right']);
    });
  });

  test('moving cancels the long press', () {
    run((async) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..moveTo(1, const Offset(20, 0), ms(100));
      async.elapse(ms(600));
      gestures.up(1, ms(600));

      expect(sink.calls, ['move']);
    });
  });

  test('tap, then slide, drags with the left button held', () {
    run((_) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..up(1, ms(80))
        ..down(2, Offset.zero, ms(200))
        ..moveTo(2, const Offset(30, 0), ms(240))
        ..moveTo(2, const Offset(60, 0), ms(280))
        ..up(2, ms(500));

      expect(sink.calls, [
        'click left',
        'press left',
        'move',
        'release left',
      ]);
      expect(sink.movedX, 60);
    });
  });

  test('tap, then hold still, starts a drag too', () {
    run((async) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..up(1, ms(80))
        ..down(2, Offset.zero, ms(200));
      async.elapse(ms(600));
      gestures
        ..moveTo(2, const Offset(10, 0), ms(800))
        ..up(2, ms(900));

      expect(sink.calls, ['click left', 'press left', 'move', 'release left']);
    });
  });

  test('a touch taken away mid-drag lets go of the button', () {
    run((_) {
      gestures
        ..down(1, Offset.zero, ms(0))
        ..up(1, ms(80))
        ..down(2, Offset.zero, ms(200))
        ..moveTo(2, const Offset(30, 0), ms(240))
        ..cancel(2);

      expect(sink.calls.last, 'release left');
      expect(gestures.isDragging, isFalse);
    });
  });
}
