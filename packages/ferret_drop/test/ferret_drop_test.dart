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

  test('share targets reach the platform', () async {
    final api = _FakeApi();
    final drop = FerretDrop(api: api);

    await drop.setShareTargets([
      ShareTarget(deviceId: 'phone-id', name: 'Pixel 9', kind: 'phone'),
    ]);

    expect(api.targets.single.name, 'Pixel 9');
  });

  test('a platform without a share sheet list ignores targets', () async {
    final drop = FerretDrop(api: _FakeApi()..fails = true);

    await expectLater(drop.setShareTargets(const []), completes);
  });

  test('platform failures become false instead of throwing', () async {
    final drop = FerretDrop(api: _FakeApi()..fails = true);

    expect(await drop.open('/missing'), isFalse);
    expect(await drop.reveal('/missing'), isFalse);
    expect(await drop.canSaveToDownloads(), isFalse);
  });

  group('FilePicks', () {
    const channel = MethodChannel('io.sofluffy.ferret_drop/pick');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('hands back the paths of the copies', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return ['/cache/picked/1/a.jpg', '/cache/picked/1/b.jpg'];
      });

      expect(await FilePicks.open(), [
        '/cache/picked/1/a.jpg',
        '/cache/picked/1/b.jpg',
      ]);
      expect(calls, ['pickFiles']);
    });

    test('a picker that fails or is missing picks nothing', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'busy'),
      );
      expect(await FilePicks.open(), isEmpty);

      messenger.setMockMethodCallHandler(channel, null);
      expect(await FilePicks.open(), isEmpty);
    });
  });
}

class _FakeApi implements FerretDropHostApi {
  List<SharedItems> pending = [];
  List<ShareTarget> targets = [];
  bool fails = false;

  @override
  Future<List<SharedItems>> takePendingShares() async {
    final taken = pending;
    pending = [];
    return taken;
  }

  @override
  Future<void> setShareTargets(List<ShareTarget> targets) async {
    await _answer(true);
    this.targets = targets;
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
