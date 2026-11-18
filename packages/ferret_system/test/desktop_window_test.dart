import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(DesktopWindow.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('calls reach the runner by name', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'window.startedHidden' || 'tray.set' => true,
        _ => null,
      };
    });
    final window = DesktopWindow.withChannel(channel);

    await window.setHideOnClose(true);
    await window.toggle();
    final hidden = await window.startedHidden();
    final tray = await window.setTray('Ferret', const [
      TrayMenuItem(id: 'quit', title: 'Quit'),
    ]);

    expect(calls.map((call) => call.method), [
      'window.setHideOnClose',
      'window.toggle',
      'window.startedHidden',
      'tray.set',
    ]);
    expect(calls.first.arguments, {'value': true});
    expect(hidden, isTrue);
    expect(tray, isTrue);
  });

  test('a runner without these methods changes nothing', () async {
    final window = DesktopWindow.withChannel(channel);

    expect(await window.startedHidden(), isFalse);
    expect(await window.setTray('Ferret', const []), isFalse);
    await window.show();
  });

  test('what the runner reports arrives on the streams', () async {
    final window = DesktopWindow.withChannel(channel);
    final picked = window.traySelections.first;
    final closed = window.closedToTray.first;
    const codec = StandardMethodCodec();

    await messenger.handlePlatformMessage(
      DesktopWindow.channelName,
      codec.encodeMethodCall(const MethodCall('tray.select', {'id': 'pause'})),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      DesktopWindow.channelName,
      codec.encodeMethodCall(const MethodCall('window.closedToTray')),
      (_) {},
    );

    expect(await picked, 'pause');
    await closed;
  });
}
