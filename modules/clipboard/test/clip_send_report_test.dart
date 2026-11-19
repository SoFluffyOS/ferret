import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:clipboard/l10n/l10n.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';

class _NoFeatureContext extends Fake implements FeatureContext {}

void main() {
  late FakeClipboard clipboard;
  late FakeHost host;
  late ClipboardFeatureUi ui;

  final pixel = TrustedDevice(
    id: 'pixelpixelpixelp',
    name: 'Pixel 7',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );

  Future<void> start(WidgetTester tester) async {
    final session = FakeSession(pixel.id);
    await tester.runAsync(() async {
      clipboard = FakeClipboard(access: .foreground);
      host = await FakeHost.create();
      host.sessions = [session];
      ui = ClipboardFeatureUi(
        feature: ClipboardFeature(clipboard: () => clipboard),
      );
      await ui.feature.start(host);
    });
    addTearDown(() async {
      await ui.dispose();
      await ui.feature.stop();
    });

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        localizationsDelegates: const [
          ClipboardLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: ClipboardLocalizations.supportedLocales,
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        builder: (context, child) => FluffyTheme(
          data: FluffyThemeData.fallback(),
          child: DefaultTextStyle(
            style: const TextStyle(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: Builder(
          builder: (context) {
            final action = ui
                .deviceActions(
                  context,
                  _NoFeatureContext(),
                  DeviceStatus(pixel, session),
                )
                .single;

            return Center(
              child: GestureDetector(
                onTap: action.onPressed,
                child: Text(action.label),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> sendClipboard(WidgetTester tester) async {
    await tester.tap(find.text('Send clipboard'));
    await tester.runAsync(settle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> waitOut(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('says where the clip went, out loud too', (tester) async {
    await start(tester);
    clipboard.content = const .text('copied in another app');

    await sendClipboard(tester);

    expect(find.text('Sent to Pixel 7'), findsOneWidget);
    expect(
      tester.takeAnnouncements().map((announcement) => announcement.message),
      ['Sent to Pixel 7'],
    );
    await waitOut(tester);
  });

  testWidgets('says out loud why it reached nobody', (tester) async {
    await start(tester);
    host.sessions = [];
    clipboard.content = const .text('nobody home');

    await sendClipboard(tester);

    expect(find.textContaining('No device is connected.'), findsOneWidget);
    expect(
      tester.takeAnnouncements().single.message,
      contains('No device is connected.'),
    );
    await waitOut(tester);
  });

  testWidgets('says why nothing went', (tester) async {
    await start(tester);
    clipboard.content = null;

    await sendClipboard(tester);

    expect(find.textContaining('The clipboard is empty'), findsOneWidget);
    await waitOut(tester);
  });
}
