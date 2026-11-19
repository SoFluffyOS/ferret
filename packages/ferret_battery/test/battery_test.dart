import 'dart:io';

import 'package:ferret_battery/ferret_battery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('macOS pmset', () {
    test('reads a laptop that charges', () {
      const output =
          "Now drawing from 'AC Power'\n"
          ' -InternalBattery-0 (id=4653155)\t62%; charging; 1:02 remaining '
          'present: true\n';

      expect(
        DesktopBatteryReaders.parsePmset(output),
        const BatteryLevel(62, charging: true),
      );
    });

    test('reads a laptop on battery', () {
      const output =
          "Now drawing from 'Battery Power'\n"
          ' -InternalBattery-0 (id=4653155)\t15%; discharging; 0:40 remaining '
          'present: true\n';

      expect(
        DesktopBatteryReaders.parsePmset(output),
        const BatteryLevel(15, charging: false),
      );
    });

    test('a desktop Mac has no battery', () {
      expect(
        DesktopBatteryReaders.parsePmset("Now drawing from 'AC Power'\n"),
        isNull,
      );
    });
  });

  group('Windows power status', () {
    test('a laptop on battery', () {
      expect(
        DesktopBatteryReaders.windowsLevel(acLine: 0, flag: 0, percent: 40),
        const BatteryLevel(40, charging: false),
      );
    });

    test('charging, by flag or by the power line', () {
      expect(
        DesktopBatteryReaders.windowsLevel(acLine: 0, flag: 8, percent: 40),
        const BatteryLevel(40, charging: true),
      );
      expect(
        DesktopBatteryReaders.windowsLevel(acLine: 1, flag: 1, percent: 99),
        const BatteryLevel(99, charging: true),
      );
    });

    test('a desktop PC has no battery', () {
      expect(
        DesktopBatteryReaders.windowsLevel(acLine: 1, flag: 128, percent: 255),
        isNull,
      );
    });
  });

  group('Linux sysfs', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('ferret_power'));
    tearDown(() => root.deleteSync(recursive: true));

    test('reads the first battery', () async {
      Directory('${root.path}/AC').createSync();
      final battery = Directory('${root.path}/BAT0')..createSync();
      File('${battery.path}/capacity').writeAsStringSync('73\n');
      File('${battery.path}/status').writeAsStringSync('Charging\n');

      expect(
        await DesktopBatteryReaders.linux(root: root.path),
        const BatteryLevel(73, charging: true),
      );
    });

    test('no battery folder, no battery', () async {
      Directory('${root.path}/AC').createSync();

      expect(await DesktopBatteryReaders.linux(root: root.path), isNull);
    });
  });

  test('the platform map turns into a level', () {
    expect(
      ChannelBatterySource.levelOf({'percent': 62, 'charging': false}),
      const BatteryLevel(62, charging: false),
    );
    expect(
      ChannelBatterySource.levelOf({'percent': -1, 'charging': false}),
      isNull,
    );
    expect(ChannelBatterySource.levelOf(null), isNull);
  });

  test('polling passes on only what changed', () {
    final readings = [
      const BatteryLevel(50, charging: false),
      const BatteryLevel(50, charging: false),
      const BatteryLevel(49, charging: false),
    ];
    var index = 0;
    final source = PollingBatterySource(
      () async => readings[index++ % readings.length],
      interval: const Duration(milliseconds: 10),
    );

    final seen = <BatteryLevel?>[];
    final subscription = source.changes.listen(seen.add);

    return Future<void>.delayed(const Duration(milliseconds: 45), () async {
      await subscription.cancel();
      expect(seen.take(2), [
        const BatteryLevel(50, charging: false),
        const BatteryLevel(49, charging: false),
      ]);
    });
  });
}
