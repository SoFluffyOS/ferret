import 'package:clipboard/clipboard.dart';
import 'package:clipboard/ui/frames/frames.dart';
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

  Widget card() => testApp(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: const ClipboardCardFrame(),
    ),
  );

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

  testWidgets('an empty card explains what to do', (tester) async {
    await start(tester);

    await tester.pumpWidget(card());

    expect(
      find.text('Copy something here and paste it on your other devices.'),
      findsOneWidget,
    );
    expect(find.text('Send clipboard'), findsNothing);
  });

  testWidgets('with every device offline the card says copies wait', (
    tester,
  ) async {
    await start(tester);
    host.sessions = [];

    await tester.pumpWidget(card());

    expect(
      find.text('Your devices are offline. Copies sync when one is back.'),
      findsOneWidget,
    );
    expect(find.textContaining('paste it on your other devices'), findsNothing);
  });

  testWidgets('a received clip says where it came from', (tester) async {
    await start(tester);
    await tester.pumpWidget(card());

    await tester.runAsync(
      () => feature.onEnvelope(pixel, envelopeOf(pushOf('from the phone'))),
    );
    await tester.pump();

    expect(find.text('Copied from Pixel · just now'), findsOneWidget);
    expect(find.text('from the phone'), findsOneWidget);
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('a private clip is blurred', (tester) async {
    await start(tester, settings: {ClipboardSettings.syncSensitiveKey: true});
    await tester.pumpWidget(card());

    await tester.runAsync(
      () => feature.onEnvelope(
        pixel,
        envelopeOf(pushOf('hunter2', sensitive: true)),
      ),
    );
    await tester.pump();

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('with auto receive off, Copy puts it on the clipboard', (
    tester,
  ) async {
    await start(tester, settings: {ClipboardSettings.autoReceiveKey: false});
    await tester.pumpWidget(card());
    await tester.runAsync(
      () => feature.onEnvelope(pixel, envelopeOf(pushOf('on demand'))),
    );
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(find.text('Copy'));
      await settle();
    });
    await tester.pump();

    expect(clipboard.writes.single.text, 'on demand');
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('Android keeps the card to one line and sends on tap', (
    tester,
  ) async {
    await start(tester, access: .foreground);
    clipboard.content = const .text('copied in another app');
    await tester.pumpWidget(card());

    expect(
      find.text('Copy something, then tap Send clipboard.'),
      findsOneWidget,
    );
    expect(
      find.textContaining("Android doesn't let apps read your clipboard"),
      findsNothing,
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('Send clipboard'));
      await settle();
      await settle();
    });
    await tester.pump();

    expect(pixel.pushes.single.item.text, 'copied in another app');
    expect(find.text('Sent.'), findsOneWidget);
    expect(find.text('Sent to Pixel · just now'), findsOneWidget);
  });

  testWidgets('a failed tap says why in plain words', (tester) async {
    await start(tester, access: .foreground);
    host.sessions = [];
    clipboard.content = const .text('nobody home');
    await tester.pumpWidget(card());

    await tester.runAsync(() async {
      await tester.tap(find.text('Send clipboard'));
      await settle();
      await settle();
    });
    await tester.pump();

    expect(find.textContaining('No device is connected.'), findsOneWidget);
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
