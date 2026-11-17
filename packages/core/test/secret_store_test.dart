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

  test('settings fire a change with the key', () async {
    final settings = MemorySettingsStore();
    final changed = settings.changes.first;

    await settings.set('clipboard.enabled', true);

    expect(await changed, 'clipboard.enabled');
    expect(settings.get<bool>('clipboard.enabled'), isTrue);
    expect(settings.get<String>('clipboard.enabled'), isNull);
  });
}
