import 'package:ferret_drop/ferret_drop.dart';
import 'package:ferret_drop/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pending shares arrive on the stream, then live ones', () async {
    final api = _FakeApi()
      ..pending = [
        SharedItems(paths: ['/cache/a.txt']),
      ];
    final drop = FerretDrop(api: api);

    final received = <SharedItems>[];
    final subscription = drop.shares.listen(received.add);
    await pumpEventQueue();
    drop.onShared(SharedItems(paths: const [], text: 'hello'));
    await pumpEventQueue();

    expect(received.map((items) => items.paths), [
      ['/cache/a.txt'],
      <String>[],
    ]);
    expect(received.last.text, 'hello');
    await subscription.cancel();
  });

  test('platform failures become false instead of throwing', () async {
    final drop = FerretDrop(api: _FakeApi()..fails = true);

    expect(await drop.open('/missing'), isFalse);
    expect(await drop.reveal('/missing'), isFalse);
    expect(await drop.canSaveToDownloads(), isFalse);
  });
}

class _FakeApi implements FerretDropHostApi {
  List<SharedItems> pending = [];
  bool fails = false;

  @override
  Future<List<SharedItems>> takePendingShares() async {
    final taken = pending;
    pending = [];
    return taken;
  }

  @override
  Future<bool> canSaveToDownloads() => _answer(true);

  @override
  Future<bool> open(String location, String mimeType) => _answer(true);

  @override
  Future<bool> reveal(String location) => _answer(true);

  @override
  Future<SavedFile> saveToDownloads(
    String sourcePath,
    String fileName,
    String mimeType,
    String folder,
  ) async => SavedFile(location: 'content://1', name: fileName);

  Future<T> _answer<T>(T value) async {
    if (fails) {
      throw PlatformException(code: 'unsupported');
    }

    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
