import 'dart:io';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_send_handoff');
  });

  tearDown(() => root.delete(recursive: true));

  test('a launch while Ferret is still getting ready waits for it', () async {
    final starting = SendHandoff(root.path);
    final later = SendHandoff(root.path);
    await starting.listen();

    expect(await later.wakeUp(), isTrue);
    expect(await later.handOver(['/tmp/a.txt']), isTrue);

    final received = <List<String>>[];
    starting.requests.listen(received.add);
    await Future<void>.delayed(Duration.zero);

    expect(received, [
      <String>[],
      ['/tmp/a.txt'],
    ]);
    await starting.dispose();
    await later.dispose();
  });

  test('listening twice keeps the first address', () async {
    final running = SendHandoff(root.path);
    await Future.wait([running.listen(), running.listen()]);
    final address = await File('${root.path}/send_handoff.json').readAsString();

    await running.listen();

    expect(
      await File('${root.path}/send_handoff.json').readAsString(),
      address,
    );
    await running.dispose();
  });
}
