import 'dart:io';

import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/test_app.dart';
import 'support/transfers.dart';

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final l10n = lookupDropLocalizations(const Locale('en'));
  final featureContext = _NoContext();
  late LinkedDevices link;

  Future<DropFeatureUi> start({
    Map<String, Object?> settings = const {},
  }) async {
    final inbox = Directory.systemTemp.createTempSync('ferret_drop_settings');
    addTearDown(() => inbox.deleteSync(recursive: true));
    link = await LinkedDevices.start(
      laptopStore: folderStore(inbox),
      phoneStore: folderStore(inbox),
      laptopSettings: settings,
      localSend: const LocalSendOptions(
        useMulticast: false,
        scanAddresses: false,
        multicastWait: Duration.zero,
      ),
    );
    final ui = DropFeatureUi(feature: link.laptop.feature);
    addTearDown(ui.dispose);
    return ui;
  }

  Future<List<FeatureSettings>> sections(
    WidgetTester tester,
    DropFeatureUi ui,
  ) async {
    late List<FeatureSettings> parts;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            parts = ui.settingsSections(context, featureContext);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return parts;
  }

  group('the Settings parts', () {
    testWidgets('where files go sits under Files, the apps under Other apps', (
      tester,
    ) async {
      final ui = await start();

      final [files, localSend, quickShare] = await sections(tester, ui);

      expect(files.group, SettingsGroup.files);
      expect(files.title, 'Files');
      expect(files.isOn, isNull);
      expect(files.needsAttention, isFalse);
      expect(localSend.group, SettingsGroup.otherApps);
      expect(localSend.title, 'LocalSend');
      expect(localSend.summary, 'Receives when you allow it');
      expect(localSend.isOn, isFalse);
      expect(localSend.needsAttention, isFalse);
      expect(quickShare.group, SettingsGroup.otherApps);
      expect(quickShare.title, 'Quick Share');
      expect(quickShare.isOn, isFalse);
      expect(quickShare.needsAttention, isFalse);
    });

    testWidgets('an app turned off says Off, and the row hears about it', (
      tester,
    ) async {
      final ui = await start();
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await link.laptop.feature.localSend.setEnabled(false);
      await link.laptop.feature.quickShare.setEnabled(false);
      await tester.pump();

      final [_, localSend, quickShare] = await sections(tester, ui);
      expect(changes, greaterThan(0));
      expect(localSend.summary, 'Off');
      expect(localSend.isOn, isFalse);
      expect(quickShare.summary, 'Off');
    });

    testWidgets('each part shows only its own switches', (tester) async {
      final ui = await start();
      final [files, localSend, quickShare] = await sections(tester, ui);

      await tester.pumpWidget(testApp(files.child));
      expect(find.text('Accept from my devices'), findsOneWidget);
      expect(find.text('Work with LocalSend'), findsNothing);
      expect(find.text('Work with Quick Share'), findsNothing);

      await tester.pumpWidget(testApp(localSend.child));
      expect(find.text('Work with LocalSend'), findsOneWidget);
      expect(find.text('Accept from my devices'), findsNothing);

      await tester.pumpWidget(testApp(quickShare.child));
      expect(find.text('Work with Quick Share'), findsOneWidget);
      expect(find.text('Work with LocalSend'), findsNothing);
    });

    test('the Files row says where files go', () {
      expect(
        filesSummaryOf(l10n, 'Downloads › Ferret'),
        'To Downloads › Ferret',
      );
      expect(filesSummaryOf(l10n, ''), '');
    });

    test('LocalSend says whether it receives', () {
      String summary({
        bool isEnabled = true,
        bool receiveAlways = false,
        LocalSendReceiveState state = const LocalSendReceiveState(),
      }) => localSendSummaryOf(
        l10n,
        isEnabled: isEnabled,
        receiveAlways: receiveAlways,
        state: state,
      );

      expect(summary(isEnabled: false), 'Off');
      expect(summary(), 'Receives when you allow it');
      expect(
        summary(state: const LocalSendReceiveState(isOn: true)),
        'Receiving now',
      );
      expect(
        summary(
          receiveAlways: true,
          state: const LocalSendReceiveState(isOn: true),
        ),
        'Always receives',
      );
      expect(
        summary(
          receiveAlways: true,
          state: const LocalSendReceiveState(problem: .cannotListen),
        ),
        "Can't receive right now",
      );
    });

    test('Quick Share says whether phones can send now', () {
      expect(
        quickShareSummaryOf(
          l10n,
          isEnabled: true,
          state: const QuickShareReceiveState(isOn: true),
        ),
        'Receiving now',
      );
      expect(
        quickShareSummaryOf(
          l10n,
          isEnabled: true,
          state: const QuickShareReceiveState(),
        ),
        'Receives when you allow it',
      );
    });
  });

  testWidgets('always receiving that cannot start says so, without red', (
    tester,
  ) async {
    await start();
    final viewModel = _StuckViewModel(link.laptop.feature);
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider<DropViewModel>.value(
          value: viewModel,
          child: const LocalSendSettingsFrame(),
        ),
      ),
    );

    final problem = tester.widget<Text>(
      find.textContaining("Couldn't start."),
    );
    final palette = tester.element(find.byType(LocalSendSettingsFrame)).palette;
    expect(problem.style?.color, palette.warning);
    expect(find.text('Try again'), findsOneWidget);
  });

  group('health says how the last transfer really ended', () {
    FeatureHealth health(Transfer? last, {void Function()? onRetry}) =>
        dropHealthOf(
          l10n,
          name: 'Pixel',
          supported: true,
          last: last,
          folder: 'Downloads › Ferret',
          onRetry: onRetry,
        );

    test('nothing sent yet says where files arrive', () {
      expect(health(null).state, FeatureHealthState.ok);
      expect(health(null).reason, 'Arrive in Downloads › Ferret');
    });

    test('a device without Files is off', () {
      final off = dropHealthOf(
        l10n,
        name: 'Pixel',
        supported: false,
        last: null,
        folder: '',
      );

      expect(off.state, FeatureHealthState.off);
      expect(off.reason, 'Pixel needs a newer Ferret to receive files.');
    });

    test('what arrived, each way', () {
      expect(
        health(sampleTransfer(direction: .outgoing, status: .done)).reason,
        'Pixel got the last thing you sent',
      );
      expect(
        health(sampleTransfer(status: .done)).reason,
        'The last thing Pixel sent arrived',
      );
    });

    test('a no is said for the side that said it', () {
      final theyDeclined = health(
        sampleTransfer(
          direction: .outgoing,
          status: .failed,
          failure: .declined,
        ),
      );
      final declinedHere = health(
        sampleTransfer(status: .cancelled, failure: .declined),
      );

      expect(theyDeclined.state, FeatureHealthState.ok);
      expect(theyDeclined.reason, 'Pixel declined the last thing you sent');
      expect(declinedHere.reason, 'You declined the last thing Pixel sent');
    });

    test('a cancel is said for the side that cancelled', () {
      expect(
        health(
          sampleTransfer(status: .cancelled, failure: .cancelledByPeer),
        ).reason,
        'Pixel cancelled the last transfer',
      );
      expect(
        health(
          sampleTransfer(direction: .outgoing, status: .cancelled),
        ).reason,
        'You cancelled the last transfer',
      );
    });

    test('an offer nobody answered is not a failure', () {
      final unanswered = health(
        sampleTransfer(
          direction: .outgoing,
          status: .failed,
          failure: .timedOut,
        ),
      );

      expect(unanswered.state, FeatureHealthState.ok);
      expect(unanswered.reason, "Pixel didn't answer the last time you sent");
    });

    test('a broken transfer offers the retry, or says who sends again', () {
      var retries = 0;
      final broken = sampleTransfer(
        direction: .outgoing,
        status: .failed,
        failure: .disconnected,
      );

      final fixable = health(broken, onRetry: () => retries++);
      fixable.onFix?.call();

      expect(fixable.state, FeatureHealthState.failing);
      expect(retries, 1);
      expect(health(broken).onFix, isNull);
      expect(health(broken).help, 'Send the files again from here.');
      expect(
        health(sampleTransfer(status: .failed, failure: .checksum)).help,
        'On Pixel: send the files again.',
      );
    });
  });
}

/// A view model whose LocalSend receiving couldn't start.
class _StuckViewModel extends DropViewModel {
  _StuckViewModel(DropFeature feature) : super(feature: feature);

  @override
  bool get receiveAlways => true;

  @override
  LocalSendReceiveState get receiveState =>
      const LocalSendReceiveState(problem: .cannotListen);
}
