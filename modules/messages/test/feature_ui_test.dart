import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:messages/ui/ui.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

class _FakeEngine implements FerretEngine {
  _FakeEngine([this._trustStore]);

  final TrustStore? _trustStore;

  @override
  TrustStore get trustStore => _trustStore ?? (throw UnimplementedError());

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

  group('the home card on a computer', () {
    late TrustStore trustStore;
    late FeatureContext trusted;
    late int reveals;

    setUp(() async {
      trustStore = await TrustStore.open(MemorySecretStore());
      await trustStore.save(pixel);
      reveals = 0;
      trusted = FeatureContext(
        engine: _FakeEngine(trustStore),
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: FakeNotifier(),
        onReveal: () async => reveals++,
      );
    });

    tearDown(() => ui.dispose());

    test('shows once a paired phone shares its texts', () async {
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);
      final before = ui.hasHomeCard(trusted);

      await devices.connect();
      await Future<void>.delayed(Duration.zero);

      expect(before, isFalse);
      expect(ui.hasHomeCard(trusted), isTrue);
      expect(changes, greaterThan(0));
    });

    test('a tapped notice brings the app to the front', () async {
      final notifier = FakeNotifier();
      final revealing = FeatureContext(
        engine: _FakeEngine(trustStore),
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: notifier,
        onReveal: () async => reveals++,
      );
      await ui.onAppStarted(revealing);

      notifier.respond(
        NoticeResponse(
          noticeId: IncomingNotices.noticeIdFor(PhoneAndComputer.phoneId, 1),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(reveals, 1);
    });
  });

  group('on the phone', () {
    late MessagesFeature phone;
    late MessagesFeatureUi phoneUi;

    Future<void> startPhone(
      WidgetTester tester, {
      required bool enabled,
      FakeSmsSource? sms,
    }) async {
      await tester.runAsync(() async {
        phone = MessagesFeature(source: sms ?? FakeSmsSource());
        await phone.start(FakeHost({MessagesSettings.enabledKey: enabled}));
      });
      phoneUi = MessagesFeatureUi.withFeature(phone);
      await tester.pumpWidget(testApp(const SizedBox()));
      await tester.pumpAndSettle();
      addTearDown(() => tester.runAsync(phone.stop));
    }

    FeatureOffer? offer(WidgetTester tester) => phoneUi.offerFor(
      tester.element(find.byType(ListView)),
      context,
    );

    testWidgets('offers Messages while they are off, with no card', (
      tester,
    ) async {
      await startPhone(tester, enabled: false);

      expect(offer(tester)?.title, 'Messages');
      expect(
        offer(tester)?.description,
        'Read and reply to texts from your computer.',
      );
      expect(offer(tester)?.actionLabel, 'Set up');
      expect(phoneUi.hasHomeCard(context), isFalse);
    });

    testWidgets('once on and working, neither an offer nor a card', (
      tester,
    ) async {
      await startPhone(tester, enabled: false);
      var changes = 0;
      phoneUi.uiChanges.addListener(() => changes++);

      await tester.runAsync(() async {
        await phone.settings.setEnabled(true);
        await Future<void>.delayed(Duration.zero);
      });

      expect(offer(tester), isNull);
      expect(phoneUi.hasHomeCard(context), isFalse);
      expect(changes, greaterThan(0));
    });

    testWidgets('on without SMS access, the card asks for a fix', (
      tester,
    ) async {
      await startPhone(
        tester,
        enabled: true,
        sms: FakeSmsSource(canRead: false),
      );

      expect(offer(tester), isNull);
      expect(phoneUi.hasHomeCard(context), isTrue);
    });

    testWidgets('a phone that cannot text offers nothing', (tester) async {
      await startPhone(
        tester,
        enabled: false,
        sms: FakeSmsSource(hasTelephony: false),
      );

      expect(offer(tester), isNull);
      expect(phoneUi.hasHomeCard(context), isFalse);
    });

    testWidgets('the card says what is wrong and offers Fix', (tester) async {
      final sms = FakeSmsSource(canRead: false);
      await startPhone(tester, enabled: true, sms: sms);
      final service = phone.sourceService;
      if (service == null) {
        fail('a phone has a source service');
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => PhoneSetupViewModel(service),
            child: PhoneCardFrame(onSetUp: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Messages are on, but Ferret can't read your texts yet."),
        findsOneWidget,
      );
      expect(find.text('Fix'), findsOneWidget);
    });
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

  testWidgets('forgetting saved texts asks first, in red', (tester) async {
    await tester.runAsync(devices.connect);
    await tester.runAsync(
      () => devices.library.loadOlderConversations(PhoneAndComputer.phoneId),
    );

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider(
          create: (_) => ComputerSettingsViewModel(
            settings: devices.computer.settings,
            library: devices.library,
          ),
          child: const ComputerSettingsFrame(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final forget = find.widgetWithText(Button, 'Forget saved texts');
    expect(forget, findsOneWidget);
    expect(tester.widget<Button>(forget).color, isNotNull);

    await tester.tap(forget);
    await tester.pumpAndSettle();
    expect(find.text('Forget saved texts?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(devices.library.hasHistory(PhoneAndComputer.phoneId), isTrue);

    await tester.tap(forget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(devices.library.hasHistory(PhoneAndComputer.phoneId), isFalse);
    expect(find.text('Forget saved texts'), findsNothing);

    await tester.runAsync(devices.stop);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
