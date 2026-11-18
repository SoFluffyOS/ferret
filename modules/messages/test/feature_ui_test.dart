import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:messages/ui/ui.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSmsSource source;
  late PhoneAndComputer devices;
  late MessagesFeatureUi ui;
  late FeatureContext context;

  final pixel = TrustedDevice(
    id: PhoneAndComputer.phoneId,
    name: 'Pixel',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );

  setUp(() async {
    source = FakeSmsSource()
      ..addConversation(conversationOf(1, lastDateMs: 1000, unread: 3));
    devices = await PhoneAndComputer.start(source: source);
    ui = MessagesFeatureUi.withFeature(devices.computer);
    context = FeatureContext(
      engine: _FakeEngine(),
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: FakeNotifier(),
    );
  });

  tearDown(() => devices.stop());

  FeatureHealth? health() =>
      ui.healthFor(context, DeviceStatus(pixel, devices.toPhone));

  test('the feature and its UI share one id', () {
    expect(ui.featureId, MessagesFeature.featureId);
    expect(ui.feature.id, MessagesFeature.featureId);
    expect(ui.noticeCategories.map((category) => category.id), [
      'messages.message',
      'messages.group',
    ]);
  });

  test('health is real: ready after a round trip', () async {
    await devices.connect();

    expect(health()?.state, FeatureHealthState.ok);
  });

  test('health says when Messages is off on the phone', () async {
    await devices.phone.settings.setEnabled(false);
    await devices.connect();

    expect(health()?.state, FeatureHealthState.off);
    expect(health()?.reason, contains('Messages are off on Pixel'));
  });

  test('health asks for attention when the phone lacks SMS access', () async {
    source.canRead = false;
    await devices.phone.sourceService?.refreshAccess();
    await devices.connect();

    expect(health()?.state, FeatureHealthState.needsAttention);
  });

  test('health fails when the phone stopped answering', () async {
    await devices.connect();
    devices.toPhone?.unresponsive = true;

    await devices.library.loadOlderConversations(PhoneAndComputer.phoneId);
    await devices.library.loadNewestMessages(PhoneAndComputer.phoneId, 1);

    expect(health()?.state, FeatureHealthState.failing);
  });

  test('no chip for a device that is not connected', () {
    expect(ui.healthFor(context, DeviceStatus(pixel, null)), isNull);
  });

  testWidgets('the home card shows unread texts per phone', (tester) async {
    await tester.runAsync(devices.connect);

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider(
          create: (_) => CardViewModel(
            library: devices.library,
            deviceName: (_) => 'Pixel',
            isPaired: (_) => true,
          ),
          child: MessagesCardFrame(onOpen: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Messages · Pixel'), findsOneWidget);
    expect(find.text('3 unread texts'), findsOneWidget);
    expect(find.text('Alex: Hi'), findsOneWidget);

    await tester.runAsync(devices.stop);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
