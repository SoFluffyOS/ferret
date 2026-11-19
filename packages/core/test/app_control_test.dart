import 'dart:io';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_app_control');
  });

  tearDown(() => root.delete(recursive: true));

  test('a command reaches the running app and its answer comes back', () async {
    final running = AppControl(root.path);
    final asked = <(String, Map<String, Object?>)>[];
    await running.listen((command, arguments) async {
      asked.add((command, arguments));
      return {'ok': true, 'device': arguments['device']};
    });
    addTearDown(running.dispose);

    final answer = await AppControl(
      root.path,
    ).ask('ring', {'device': 'Pixel'});

    expect(answer, {'ok': true, 'device': 'Pixel'});
    expect(asked.single.$1, 'ring');
  });

  test('asking with no app running answers null', () async {
    expect(await AppControl(root.path).ask('ring'), isNull);
  });

  test('a stopped app no longer answers', () async {
    final running = AppControl(root.path);
    await running.listen((_, _) async => {'ok': true});
    await running.dispose();

    expect(await AppControl(root.path).ask('ring'), isNull);
  });
}
