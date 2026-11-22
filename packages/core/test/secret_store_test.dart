import 'dart:io';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('a file secret store keeps values across instances', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_core');
    addTearDown(() => directory.delete(recursive: true));

    await FileSecretStore(directory.path).write('identity', 'secret');
    final reopened = FileSecretStore(directory.path);

    expect(await reopened.read('identity'), 'secret');
    if (!Platform.isWindows) {
      final mode = (await File(
        '${directory.path}/secrets.json',
      ).stat()).modeString();
      expect(mode, 'rw-------');
    }
  });

  test('writes at the same moment all land, and the file reads back', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_core');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileSecretStore(directory.path);

    await Future.wait([
      for (var index = 0; index < 20; index++)
        store.write('key$index', 'value$index'),
    ]);
    final reopened = FileSecretStore(directory.path);

    for (var index = 0; index < 20; index++) {
      expect(await reopened.read('key$index'), 'value$index');
    }
  });

  test('settings changed at the same moment are all saved', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_core');
    addTearDown(() => directory.delete(recursive: true));
    final settings = await JsonFileSettingsStore.open(directory.path);

    await Future.wait([
      for (var index = 0; index < 20; index++)
        settings.set('shell.key$index', index),
    ]);
    final reopened = await JsonFileSettingsStore.open(directory.path);

    for (var index = 0; index < 20; index++) {
      expect(reopened.get<int>('shell.key$index'), index);
    }
  });

  test('a settings file cut short starts over and is kept aside', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_core');
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/settings.json').writeAsString('{"a": tr');

    final settings = await JsonFileSettingsStore.open(directory.path);

    expect(settings.get<bool>('a'), isNull);
    expect(
      await File('${directory.path}/settings.json.unreadable').readAsString(),
      '{"a": tr',
    );
    await settings.set('a', true);
    final reopened = await JsonFileSettingsStore.open(directory.path);
    expect(reopened.get<bool>('a'), isTrue);
  });

  test(
    'settings saved by an older build keep keys this one no longer reads',
    () async {
      final directory = await Directory.systemTemp.createTemp('ferret_core');
      addTearDown(() => directory.delete(recursive: true));
      await File('${directory.path}/settings.json').writeAsString(
        '{"power.card_dismissed": true, "mirroring.actual_size": 1}',
      );

      final settings = await JsonFileSettingsStore.open(directory.path);
      await settings.set('shell.language', 'vi');
      final reopened = await JsonFileSettingsStore.open(directory.path);

      expect(reopened.get<bool>('power.card_dismissed'), isTrue);
      expect(reopened.get<bool>('mirroring.actual_size'), isNull);
      expect(reopened.get<String>('shell.language'), 'vi');
    },
  );

  test('settings fire a change with the key', () async {
    final settings = MemorySettingsStore();
    final changed = settings.changes.first;

    await settings.set('clipboard.enabled', true);

    expect(await changed, 'clipboard.enabled');
    expect(settings.get<bool>('clipboard.enabled'), isTrue);
    expect(settings.get<String>('clipboard.enabled'), isNull);
  });
}
