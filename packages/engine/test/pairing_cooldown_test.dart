import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  late DateTime now;
  late PairingCooldown cooldown;

  setUp(() {
    now = DateTime(2026, 11, 21, 12);
    cooldown = PairingCooldown(now: () => now);
  });

  bool holds({String host = '192.168.1.40', String id = 'neighbour'}) =>
      cooldown.holds(host: host, deviceId: id);

  void strike({String host = '192.168.1.40', String id = 'neighbour'}) =>
      cooldown.strike(host: host, deviceId: id);

  test('a no makes the asker wait a minute', () {
    expect(holds(), isFalse);

    strike();

    expect(holds(), isTrue);
    now = now.add(const Duration(seconds: 59));
    expect(holds(), isTrue);
    now = now.add(const Duration(seconds: 1));
    expect(holds(), isFalse);
  });

  test('the address and the device id each wait', () {
    strike();

    expect(holds(id: 'a-new-key'), isTrue);
    expect(holds(host: '192.168.1.41'), isTrue);
    expect(holds(host: '192.168.1.41', id: 'someone-else'), isFalse);
  });

  test('each further no doubles the wait, up to ten minutes', () {
    final waits = <Duration>[];
    for (var i = 0; i < 6; i++) {
      strike();
      final start = now;
      while (holds()) {
        now = now.add(const Duration(seconds: 1));
      }
      waits.add(now.difference(start));
    }

    expect(waits, const [
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 4),
      Duration(minutes: 8),
      Duration(minutes: 10),
      Duration(minutes: 10),
    ]);
  });

  test('a quiet hour starts it over', () {
    strike();
    strike();
    now = now.add(const Duration(hours: 1));

    strike();

    now = now.add(const Duration(minutes: 1));
    expect(holds(), isFalse);
  });
}
