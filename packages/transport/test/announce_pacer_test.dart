import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  AnnouncePacer pacer() => AnnouncePacer(
    interval: const Duration(seconds: 30),
    relaxedInterval: const Duration(minutes: 5),
  );

  test('announces every 30 s until relaxed, then every 5 minutes', () {
    fakeAsync((async) {
      final pace = pacer();
      var ticks = 0;
      pace.start(() => ticks++);

      async.elapse(const Duration(minutes: 10));
      expect(ticks, 20);

      ticks = 0;
      pace.setRelaxed(true);
      async.elapse(const Duration(hours: 1));
      expect(ticks, 12, reason: '120 before');
      pace.stop();
    });
  });

  test('back to the usual pace announces at once', () {
    fakeAsync((async) {
      final pace = pacer()..setRelaxed(true);
      var ticks = 0;
      pace.start(() => ticks++);
      async.elapse(const Duration(minutes: 1));
      expect(ticks, 0);

      pace.setRelaxed(false);
      expect(ticks, 1);
      async.elapse(const Duration(seconds: 30));
      expect(ticks, 2);
      pace.stop();
    });
  });

  test('stopped, it neither ticks nor announces when the pace changes', () {
    fakeAsync((async) {
      final pace = pacer();
      var ticks = 0;
      pace
        ..start(() => ticks++)
        ..stop()
        ..setRelaxed(true)
        ..setRelaxed(false);
      async.elapse(const Duration(minutes: 10));

      expect(ticks, 0);
      expect(pace.isRunning, isFalse);
    });
  });

  test('an announce heard twice, by multicast and by broadcast, goes '
      'through once', () {
    fakeAsync((async) {
      final gate = RepeatGate();

      expect(gate.pass('pixel 192.168.1.91'), isTrue);
      expect(gate.pass('pixel 192.168.1.91'), isFalse);
      expect(gate.pass('mac 192.168.1.83'), isTrue);

      async.elapse(const Duration(seconds: 2));
      expect(gate.pass('pixel 192.168.1.91'), isTrue);
    });
  });
}
