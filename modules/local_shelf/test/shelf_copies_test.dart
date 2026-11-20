import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;

import 'helpers/fake_host.dart';

void main() {
  late Directory root;
  late DateTime now;
  late FakeHost host;
  late ShelfFeature feature;
  late ShelfStore store;

  Future<ShelfItem?> copy(String text) async {
    await feature.keepCopy(text: text);
    return store.items.where((item) => item.name == text).firstOrNull;
  }

  Future<ShelfItem?> drop(String text) =>
      store.keepText(text, isLink: false, source: .dropped);

  List<String> names() => [for (final item in store.items) item.name];

  setUp(() async {
    root = Directory.systemTemp.createTempSync('shelf_copies_test');
    now = DateTime(2026, 11, 20, 9);
    host = FakeHost();
    feature = ShelfFeature(clock: () => now);
    store = ShelfStore(
      p.join(root.path, 'shelf'),
      clock: () => now,
    );
    await feature.start(host);
    feature.use(store);
    await store.load();
  });

  tearDown(() async {
    await feature.stop();
    root.deleteSync(recursive: true);
  });

  test('copies stay off the shelf until Keep copies is on', () async {
    expect(feature.settings.keepCopies, isFalse);

    expect(await copy('secret-ish'), isNull);
    expect(store.items, isEmpty);

    await feature.settings.setKeepCopies(true);
    expect(await copy('hello'), isNotNull);
  });

  test(
    'turning Keep copies off takes copies off, never what was dropped',
    () async {
      await feature.settings.setKeepCopies(true);
      final copied = await copy('copied');
      await drop('dropped');

      await feature.settings.setKeepCopies(false);
      await pumpEventQueue();

      expect(names(), ['dropped']);
      expect(File(copied!.path).existsSync(), isFalse);
    },
  );

  test('copies kept until quit go when Ferret stops', () async {
    await feature.settings.setKeepCopies(true);
    await copy('copied');
    await drop('dropped');

    await feature.stop();

    expect(names(), ['dropped']);
  });

  test('copies kept until quit from the last run go on launch', () async {
    await feature.settings.setKeepCopies(true);
    await copy('copied');
    await drop('dropped');

    await feature.tidyOnLaunch();

    expect(names(), ['dropped']);
  });

  test('copies kept for a day stay across a restart, then go', () async {
    await feature.settings.setKeepCopies(true);
    await feature.settings.setCopiesFor(.day);
    await copy('old');
    now = now.add(const Duration(hours: 20));
    await copy('new');
    await drop('dropped');

    await feature.stop();
    await feature.tidyOnLaunch();
    expect(names(), ['dropped', 'new', 'old']);

    now = now.add(const Duration(hours: 5));
    await feature.expire();
    expect(names(), ['dropped', 'new']);
  });

  test('a launch with Keep copies off clears copies from before', () async {
    await feature.settings.setKeepCopies(true);
    await feature.settings.setCopiesFor(.week);
    await copy('copied');
    await feature.stop();
    await host.settings.set(ShelfSettings.keepCopiesKey, false);

    await feature.tidyOnLaunch();

    expect(store.items, isEmpty);
  });

  test('choosing a shorter time takes older copies off right away', () async {
    await feature.settings.setKeepCopies(true);
    await feature.settings.setCopiesFor(.week);
    await copy('three days old');
    now = now.add(const Duration(days: 3));

    await feature.settings.setCopiesFor(.day);
    await pumpEventQueue();

    expect(store.items, isEmpty);
  });
}
