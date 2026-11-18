import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:ferret_handoff/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('platforms without a feature answer neutrally', () async {
    final handoff = FerretHandoff(
      api: _ThrowingApi(),
      isAndroid: false,
      isMacOS: false,
    );

    expect(await handoff.takePending(), isEmpty);
    expect(await handoff.openInApp('https://example.org', 'app'), isFalse);
    expect(await handoff.isAssistantEnabled(), isFalse);
    expect(await handoff.currentBrowserTab(), isNull);
    expect(await handoff.browserAccess(), BrowserAccess.unsupported);
    await handoff.setDevices([HandoffDevice(id: 'a', name: 'A')]);
    await handoff.setBrowserWatch(true);
  });

  test('shared items go to the handler, and wait without one', () async {
    final handoff = FerretHandoff(
      api: _ThrowingApi(),
      isAndroid: false,
      isMacOS: false,
    );
    final item = SharedItem(origin: .shareSheet, createdAtMs: 1, text: 'hi');

    await expectLater(
      handoff.onShared(item),
      throwsA(isA<PlatformException>()),
    );

    SharedItem? received;
    handoff.listen((item) async {
      received = item;
      return true;
    });

    expect(await handoff.onShared(item), isTrue);
    expect(received?.text, 'hi');
  });

  test('browser deactivation is a stream', () async {
    final handoff = FerretHandoff(
      api: _ThrowingApi(),
      isAndroid: false,
      isMacOS: true,
    );
    final next = handoff.browserDeactivated.first;

    handoff.onBrowserDeactivated('com.apple.Safari');

    expect(await next, 'com.apple.Safari');
  });
}

class _ThrowingApi implements HandoffHostApi {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No platform call expected');
}
