import 'package:clipboard/clipboard.dart';
import 'package:clipboard/ui/frames/frames.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final context = _NoContext();
  const shizukuReady = PowerStatus(supported: true, shizuku: .ready);
  const shizukuStopped = PowerStatus(supported: true, shizuku: .notRunning);
  const backgroundOn = {ClipboardSettings.backgroundSendKey: true};

  late FakeClipboard clipboard;
  late FakePowerPlatform phone;
  late PowerCapabilities power;
  late FakeHost host;
  late FakeSession laptop;
  late ClipboardFeature feature;

  Future<void> start({
    Map<String, Object?>? settings,
    ClipboardAccess access = .foreground,
    PowerStatus status = shizukuReady,
    bool shizukuEnabled = true,
  }) async {
    clipboard = FakeClipboard(access: access);
    phone = FakePowerPlatform(status: status);
    power = PowerCapabilities.withPlatform(phone);
    await power.configure(shizuku: shizukuEnabled, root: false);
    host = await FakeHost.create(settings: settings);
    laptop = FakeSession('laptoplaptoplapt', name: 'Laptop');
    host.sessions = [laptop];
    feature = ClipboardFeature(clipboard: () => clipboard, power: () => power);
    await feature.start(host);
    await settle();
  }

  Future<void> stop() async {
    await feature.stop();
    await power.dispose();
  }

  group('background sending', () {
    tearDown(stop);

    test('a copy in another app is sent on its own', () async {
      await start(settings: backgroundOn);
      expect(phone.watchedTier, PowerTier.shizuku);
      expect(feature.sendsInBackground, isTrue);

      phone.copy('copied in the browser');
      await settle();

      expect(laptop.pushes.single.item.text, 'copied in the browser');
      expect(feature.latest?.direction, ClipDirection.sent);
    });

    test('nothing is watched until the user turns it on', () async {
      await start();

      phone.copy('not asked for');
      await settle();

      expect(feature.canSendInBackground, isTrue);
      expect(feature.sendsInBackground, isFalse);
      expect(phone.shellCalls, isEmpty);
      expect(laptop.pushes, isEmpty);
    });

    test('turning the setting on and off starts and stops it', () async {
      await start();

      await feature.settings.setBackgroundSend(true);
      await settle();
      expect(phone.watchedTier, PowerTier.shizuku);

      await feature.settings.setBackgroundSend(false);
      await settle();
      expect(phone.watchedTier, isNull);
    });

    test('"Send automatically" off wins', () async {
      await start(
        settings: {...backgroundOn, ClipboardSettings.autoSendKey: false},
      );

      phone.copy('quiet');
      await settle();

      expect(phone.shellCalls, isEmpty);
      expect(laptop.pushes, isEmpty);
    });

    test('without a power-up the setting alone does nothing', () async {
      await start(settings: backgroundOn, shizukuEnabled: false);

      phone.copy('no tier');
      await settle();

      expect(feature.canSendInBackground, isFalse);
      expect(phone.shellCalls, isEmpty);
      expect(laptop.pushes, isEmpty);
    });

    test('it follows the power-up stopping and coming back', () async {
      await start(settings: backgroundOn);
      var changes = 0;
      feature.changes.listen((_) => changes++);

      phone.emit(shizukuStopped);
      await settle();
      expect(feature.sendsInBackground, isFalse);
      expect(phone.watchedTier, isNull);
      expect(changes, greaterThan(0));

      phone.emit(shizukuReady);
      await settle();
      await settle();
      phone.copy('back again');
      await settle();

      expect(laptop.pushes.single.item.text, 'back again');
    });

    test('private items stay here, as with any other copy', () async {
      await start(settings: backgroundOn);

      phone.copy('hunter2', sensitive: true);
      await settle();

      expect(laptop.pushes, isEmpty);
      expect(feature.latest?.skip, ClipSkip.sensitive);
      expect(feature.latest?.item.text, isEmpty);
    });

    test('private items go out marked private when that is on', () async {
      await start(
        settings: {...backgroundOn, ClipboardSettings.syncSensitiveKey: true},
      );

      phone.copy('hunter2', sensitive: true);
      await settle();

      expect(laptop.pushes.single.item.sensitive, isTrue);
    });

    test('the same copy is sent once', () async {
      await start(settings: backgroundOn);

      phone.copy('twice');
      await settle();
      phone.copy('twice');
      await settle();

      expect(laptop.pushes, hasLength(1));
    });

    test('a clip that just arrived is not sent back', () async {
      await start(settings: backgroundOn);

      await feature.onEnvelope(laptop, envelopeOf(pushOf('from the laptop')));
      phone.copy('from the laptop');
      await settle();

      expect(clipboard.writes.single.text, 'from the laptop');
      expect(laptop.pushes, isEmpty);
    });

    test('a received clip read back late is still not sent back', () async {
      await start(settings: backgroundOn);

      await feature.onEnvelope(laptop, envelopeOf(pushOf('from the laptop')));
      phone.copy('from the laptop');
      await settle();
      phone.copy('from the laptop');
      await settle();

      expect(laptop.pushes, isEmpty);
    });

    test('a received clip copied again after another copy is sent', () async {
      await start(settings: backgroundOn);

      await feature.onEnvelope(laptop, envelopeOf(pushOf('from the laptop')));
      phone.copy('copied in the browser');
      await settle();
      phone.copy('from the laptop');
      await settle();

      expect(
        [for (final push in laptop.pushes) push.item.text],
        ['copied in the browser', 'from the laptop'],
      );
    });

    test('text over the size limit is not sent', () async {
      await start(settings: backgroundOn);

      phone.copy('x' * (ClipboardSettings.maxTextBytes + 1));
      await settle();

      expect(laptop.pushes, isEmpty);
      expect(feature.latest?.skip, ClipSkip.tooLarge);
    });

    test(
      'Send clipboard reads through the power-up when Android refuses',
      () async {
        await start(settings: backgroundOn);
        phone.clip = const PowerClip('read in the background');

        final result = await feature.sendClipboard();

        expect(result, ClipSendResult.sent);
        expect(laptop.pushes.single.item.text, 'read in the background');
      },
    );

    test('Send clipboard never uses the power-up unasked', () async {
      await start();
      phone.clip = const PowerClip('not for sending');

      final result = await feature.sendClipboard();

      expect(result, ClipSendResult.nothingToSend);
      expect(phone.shellCalls, isEmpty);
    });

    test('desktops never touch the power-up', () async {
      await start(settings: backgroundOn, access: .always);

      expect(feature.canSendInBackground, isFalse);
      expect(phone.shellCalls, isEmpty);
    });

    test('stopping the feature stops the watch', () async {
      await start(settings: backgroundOn);

      await feature.stop();
      await settle();

      expect(phone.watchedTier, isNull);
    });
  });

  group('the card and settings', () {
    late ClipboardViewModel viewModel;

    Future<void> startUi(
      WidgetTester tester, {
      Map<String, Object?>? settings,
      bool shizukuEnabled = true,
    }) async {
      await tester.runAsync(
        () => start(settings: settings, shizukuEnabled: shizukuEnabled),
      );
      viewModel = ClipboardViewModel(feature);
      addTearDown(() async {
        viewModel.dispose();
        await tester.runAsync(stop);
      });
    }

    Widget home() => testApp(const SizedBox.shrink(key: ValueKey('home')));

    Widget settingsSection() => testApp(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const ClipboardSettingsFrame(),
      ),
    );

    FeatureOffer? offerOf(WidgetTester tester, ClipboardFeatureUi ui) =>
        ui.offerFor(
          tester.element(find.byKey(const ValueKey('home'))),
          context,
        );

    testWidgets('without a power-up, nothing is offered', (tester) async {
      await startUi(tester, shizukuEnabled: false);
      final ui = ClipboardFeatureUi(feature: feature);
      addTearDown(ui.viewModel.dispose);

      await tester.pumpWidget(home());

      expect(viewModel.needsManualSend, isTrue);
      expect(offerOf(tester, ui), isNull);
    });

    testWidgets('with a power-up, the offer turns background sending on', (
      tester,
    ) async {
      await startUi(tester);
      final ui = ClipboardFeatureUi(feature: feature);
      addTearDown(ui.viewModel.dispose);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);
      await tester.pumpWidget(home());

      final offer = offerOf(tester, ui);
      expect(offer?.title, 'Clipboard');
      expect(
        offer?.description,
        'Send what you copy on its own, even in the background.',
      );
      await tester.runAsync(() async {
        offer?.onAction();
        await settle();
        await settle();
      });
      await tester.pump();

      expect(feature.settings.backgroundSend, isTrue);
      expect(phone.watchedTier, PowerTier.shizuku);
      expect(offerOf(tester, ui), isNull);
      expect(changes, greaterThan(0));
      expect(ui.viewModel.needsManualSend, isFalse);
    });

    testWidgets('settings explain why Send clipboard is needed', (
      tester,
    ) async {
      await startUi(tester, shizukuEnabled: false);

      await tester.pumpWidget(settingsSection());

      expect(find.text('Why Send clipboard?'), findsOneWidget);
      expect(
        find.textContaining("Android doesn't let apps read your clipboard"),
        findsOneWidget,
      );
    });

    testWidgets('settings show a lock until a power-up is on', (tester) async {
      await startUi(tester, shizukuEnabled: false);

      await tester.pumpWidget(settingsSection());

      expect(find.text('Send automatically in the background'), findsOneWidget);
      expect(
        find.text('Needs Shizuku or root. Set one up in Settings → Control.'),
        findsOneWidget,
      );
      expect(find.byType(SwitchToggle), findsNWidgets(4));
    });

    testWidgets('settings get the switch once a power-up is on', (
      tester,
    ) async {
      await startUi(tester);
      await tester.pumpWidget(settingsSection());

      expect(find.byType(SwitchToggle), findsNWidgets(5));
      await tester.runAsync(() async {
        await tester.tap(find.byType(SwitchToggle).at(1));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(feature.settings.backgroundSend, isTrue);
    });
  });
}
