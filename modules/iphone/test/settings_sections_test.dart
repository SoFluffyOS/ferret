import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Rig rig;
  late IphoneFeatureUi ui;
  late BuildContext buildContext;
  final context = FeatureContext(
    engine: _FakeEngine(),
    navigatorKey: GlobalKey<NavigatorState>(),
    notifier: RecordingNotifier(),
  );

  Future<void> start(
    WidgetTester tester, {
    Map<String, Object?>? settings,
    FakeAppleTransport? transport,
  }) async {
    rig = await Rig.start(
      settings: settings,
      transport: transport,
      retryDelays: const [],
    );
    ui = IphoneFeatureUi(feature: rig.feature);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            buildContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    ui.dispose();
    await rig.feature.stop();
    await tester.pump();
  }

  FeatureSettings part() => ui.settingsSections(buildContext, context).single;

  testWidgets('sits under Other apps as iPhone, off and quiet at first', (
    tester,
  ) async {
    await start(tester);

    expect(part().group, SettingsGroup.otherApps);
    expect(part().title, 'iPhone');
    expect(part().isOn, isFalse);
    expect(part().summary, isEmpty);
    expect(part().needsAttention, isFalse);

    await finish(tester);
  });

  testWidgets('turned on, the row follows the link', (tester) async {
    await start(tester);
    var changes = 0;
    ui.uiChanges.addListener(() => changes++);

    await rig.host.settings.set(IphoneSettings.enabledKey, true);
    await tester.pump();

    expect(changes, greaterThan(0));
    expect(part().isOn, isTrue);
    expect(part().summary, 'Pick your iPhone');
    expect(part().needsAttention, isFalse);

    await finish(tester);
  });

  testWidgets('connected says to which iPhone', (tester) async {
    await start(tester, settings: pairedSettings());

    expect(part().isOn, isTrue);
    expect(part().summary, 'Connected to Zoé’s iPhone');
    expect(part().needsAttention, isFalse);

    await finish(tester);
  });

  testWidgets('Bluetooth going off needs attention', (tester) async {
    await start(
      tester,
      settings: pairedSettings(),
      transport: FakeAppleTransport(statusNow: .off),
    );

    expect(part().summary, 'Bluetooth is off');
    expect(part().needsAttention, isTrue);

    await finish(tester);
  });

  testWidgets('an iPhone that stopped sharing needs attention', (tester) async {
    await start(
      tester,
      settings: pairedSettings(),
      transport: FakeAppleTransport(services: const AppleServices()),
    );

    expect(part().summary, 'Zoé’s iPhone isn\'t sharing');
    expect(part().needsAttention, isTrue);

    await finish(tester);
  });

  testWidgets('no part on a phone', (tester) async {
    final feature = IphoneFeature(
      transport: FakeAppleTransport.new,
      isSupported: false,
    );
    await feature.start(FakeHost(pairedSettings()));
    final phoneUi = IphoneFeatureUi(feature: feature);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            buildContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(phoneUi.settingsSections(buildContext, context), isEmpty);

    phoneUi.dispose();
    await feature.stop();
  });
}
