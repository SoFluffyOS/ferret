import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

void main() {
  late List<List<InputEvent>> sent;
  late FakeAsync async;
  late InputBatcher batcher;

  void run(void Function() body) => fakeAsync((fake) {
    async = fake;
    sent = [];
    batcher = InputBatcher(
      send: sent.add,
      clock: () => fake.getClock(DateTime(2026, 11, 18)).now(),
    );
    body();
    batcher.dispose();
  });

  List<String> kinds(List<InputEvent> events) => [
    for (final event in events) event.whichKind().name,
  ];

  test('the first move leaves at once', () {
    run(() {
      batcher.move(3, 4);

      expect(sent, hasLength(1));
      expect(sent.single.single.move.dx, 3);
      expect(sent.single.single.move.dy, 4);
    });
  });

  test('moves within one interval add up into one event', () {
    run(() {
      batcher.move(1, 0);
      batcher.move(2, 1);
      batcher.move(3, 1);
      expect(sent, hasLength(1));

      async.elapse(const Duration(milliseconds: 16));

      expect(sent, hasLength(2));
      expect(sent.last.single.move.dx, 5);
      expect(sent.last.single.move.dy, 2);
    });
  });

  test('fractions carry over instead of getting lost', () {
    run(() {
      batcher.move(0.6, -0.6);
      async.elapse(const Duration(milliseconds: 20));
      batcher.move(0.6, -0.6);

      expect(sent, hasLength(1));
      expect(sent.single.single.move.dx, 1);
      expect(sent.single.single.move.dy, -1);
    });
  });

  test('a click leaves at once, after the motion before it', () {
    run(() {
      batcher.move(5, 5);
      batcher.move(2, 0);
      batcher.scroll(0, 10);
      batcher.add(InputCodec.button(.left, pressed: true));

      expect(sent, hasLength(2));
      expect(kinds(sent.last), ['move', 'scroll', 'button']);
      expect(sent.last.first.move.dx, 2);

      async.elapse(const Duration(milliseconds: 100));
      expect(sent, hasLength(2));
    });
  });

  test('scrolls add up like moves', () {
    run(() {
      batcher.scroll(0, 4);
      batcher.scroll(0, 4);
      batcher.scroll(1, 4);
      async.elapse(const Duration(milliseconds: 16));

      expect(sent, hasLength(2));
      expect(sent.last.single.scroll.dy, 8);
      expect(sent.last.single.scroll.dx, 1);
    });
  });

  test('at most one batch per interval under a steady stream', () {
    run(() {
      for (var frame = 0; frame < 100; frame++) {
        batcher.move(1, 0);
        async.elapse(const Duration(milliseconds: 4));
      }

      expect(sent.length, lessThanOrEqualTo(26));
      final total = sent.fold<int>(
        0,
        (sum, events) => sum + events.single.move.dx,
      );
      expect(total + 0, lessThanOrEqualTo(100));
      expect(total, greaterThanOrEqualTo(96));
    });
  });

  test('nothing leaves after dispose', () {
    run(() {
      batcher.move(1, 0);
      batcher.move(1, 0);
      batcher.dispose();
      async.elapse(const Duration(milliseconds: 50));
      batcher.add(InputCodec.text('x'));

      expect(sent, hasLength(1));
    });
  });
}
