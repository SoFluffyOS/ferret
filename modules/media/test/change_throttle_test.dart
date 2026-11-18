import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

void main() {
  group('ChangeThrottle', () {
    test('sends the first change right away', () {
      fakeAsync((async) {
        final sent = <int>[];
        ChangeThrottle<int>(
          interval: const Duration(milliseconds: 500),
          onSend: sent.add,
        ).push(1);

        expect(sent, [1]);
      });
    });

    test('collapses a burst into the latest value', () {
      fakeAsync((async) {
        final sent = <int>[];
        final throttle = ChangeThrottle<int>(
          interval: const Duration(milliseconds: 500),
          onSend: sent.add,
        );

        throttle
          ..push(1)
          ..push(2)
          ..push(3)
          ..push(4);
        async.elapse(const Duration(milliseconds: 499));
        expect(sent, [1]);

        async.elapse(const Duration(milliseconds: 1));
        expect(sent, [1, 4]);

        async.elapse(const Duration(seconds: 5));
        expect(sent, [1, 4]);
      });
    });

    test('sends again right away after a quiet interval', () {
      fakeAsync((async) {
        final sent = <int>[];
        final throttle = ChangeThrottle<int>(
          interval: const Duration(milliseconds: 500),
          onSend: sent.add,
        )..push(1);

        async.elapse(const Duration(seconds: 1));
        throttle.push(2);

        expect(sent, [1, 2]);
      });
    });

    test('cancel drops what is waiting', () {
      fakeAsync((async) {
        final sent = <int>[];
        ChangeThrottle<int>(
            interval: const Duration(milliseconds: 500),
            onSend: sent.add,
          )
          ..push(1)
          ..push(2)
          ..cancel();

        async.elapse(const Duration(seconds: 1));
        expect(sent, [1]);
      });
    });
  });
}
