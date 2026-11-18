import 'package:clipboard/clipboard.dart';
import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/ui/clip_activity.dart';
import 'package:clipboard/ui/frames/frames.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late FakeClipboard clipboard;
  late FakeHost host;
  late FakeSession pixel;
  late ClipboardFeature feature;
  late ClipboardViewModel viewModel;

  Future<void> start(
    WidgetTester tester, {
    ClipboardAccess access = .always,
    Map<String, Object?>? settings,
  }) async {
    await tester.runAsync(() async {
      clipboard = FakeClipboard(access: access);
      host = await FakeHost.create(settings: settings);
      pixel = FakeSession('pixelpixelpixelp');
      host.sessions = [pixel];
      feature = ClipboardFeature(clipboard: () => clipboard);
      await feature.start(host);
    });
    viewModel = ClipboardViewModel(feature);
    addTearDown(() async {
      viewModel.dispose();
      await feature.stop();
    });
  }

  List<ActivityItem> activity() =>
      clipActivity(lookupClipboardLocalizations(const Locale('en')), viewModel);

  Widget settings() => testApp(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: const ClipboardSettingsFrame(),
    ),
  );

  test('the feature and its UI share one id', () {
    final ui = ClipboardFeatureUi();

    expect(ui.featureId, ClipboardFeature.featureId);
    expect(ui.feature.id, ClipboardFeature.featureId);
    expect(ui.uiChanges, same(ui.viewModel));
  });

  testWidgets('clipboard has no card, only its trace in Activity', (
    tester,
  ) async {
    await start(tester);
    final ui = ClipboardFeatureUi(feature: feature);
    addTearDown(ui.viewModel.dispose);

    expect(ui.hasHomeCard(_NoContext()), isFalse);
    expect(activity(), isEmpty);
  });

  testWidgets('a received clip says which device it was copied on', (
    tester,
  ) async {
    await start(tester);

    await tester.runAsync(
      () => feature.onEnvelope(pixel, envelopeOf(pushOf('from the phone'))),
    );

    final row = activity().single;
    expect(row.title, 'Copied on Pixel');
    expect(row.detail, '“from the phone”');
    expect(row.at, isNotNull);
  });

  testWidgets('a private clip never shows what it holds', (tester) async {
    await start(tester, settings: {ClipboardSettings.syncSensitiveKey: true});

    await tester.runAsync(
      () => feature.onEnvelope(
        pixel,
        envelopeOf(pushOf('hunter2', sensitive: true)),
      ),
    );

    expect(activity().single.detail, 'Private item');
  });

  testWidgets('a long clip is cut to its first words', (tester) async {
    await start(tester);

    await tester.runAsync(
      () => feature.onEnvelope(pixel, envelopeOf(pushOf('word ' * 40))),
    );

    final detail = activity().single.detail ?? '';
    expect(detail.endsWith('…”'), isTrue);
    expect(detail.length, lessThan(70));
  });

  testWidgets('Copy puts a received clip on the clipboard', (tester) async {
    await start(tester, settings: {ClipboardSettings.autoReceiveKey: false});
    await tester.runAsync(
      () => feature.onEnvelope(pixel, envelopeOf(pushOf('on demand'))),
    );

    final copy = activity().single.actions.single;
    expect(copy.label, 'Copy');
    await tester.runAsync(() async {
      copy.onPressed();
      await settle();
    });

    expect(clipboard.writes.single.text, 'on demand');
  });

  testWidgets('Send clipboard leaves a line for what was sent', (tester) async {
    await start(tester, access: .foreground);
    clipboard.content = const .text('copied in another app');

    await tester.runAsync(() async {
      await viewModel.sendClipboard();
      await settle();
    });

    expect(pixel.pushes.single.item.text, 'copied in another app');
    final row = activity().single;
    expect(row.title, 'Sent to Pixel');
    expect(row.actions, isEmpty);
  });

  testWidgets('a Send clipboard that reached nobody says why', (tester) async {
    await start(tester, access: .foreground);
    host.sessions = [];
    clipboard.content = const .text('nobody home');

    await tester.runAsync(() async {
      await viewModel.sendClipboard();
      await settle();
    });

    final row = activity().first;
    expect(row.title, 'Clipboard not sent');
    expect(row.detail, contains('No device is connected.'));
  });

  testWidgets('iPhone settings say why Send clipboard is needed', (
    tester,
  ) async {
    await start(tester, access: .onRequest);

    await tester.pumpWidget(settings());

    expect(find.text('Why Send clipboard?'), findsOneWidget);
    expect(
      find.textContaining('iPhone only lets apps read your clipboard'),
      findsOneWidget,
    );
  });

  testWidgets('settings flip their keys and clear history', (tester) async {
    await start(tester);
    await tester.runAsync(
      () => feature.onEnvelope(pixel, envelopeOf(pushOf('kept'))),
    );
    await tester.pumpWidget(settings());

    expect(find.text('1 item in history, in memory only.'), findsOneWidget);
    expect(find.text('Sync copied images up to 10 MB.'), findsOneWidget);
    expect(find.text('Why Send clipboard?'), findsNothing);

    await tester.runAsync(() async {
      await tester.tap(find.byType(SwitchToggle).at(3));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(feature.settings.syncSensitive, isTrue);

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    expect(feature.history, isEmpty);
    expect(
      find.text('History is empty. It stays in memory, never on disk.'),
      findsOneWidget,
    );
  });
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
