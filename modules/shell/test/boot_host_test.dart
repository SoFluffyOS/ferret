import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  const app = Directionality(textDirection: .ltr, child: Text('The app'));

  Future<void> clear(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('the launch look comes first, then the app fades in over it', (
    tester,
  ) async {
    final ready = Completer<Widget>();
    await tester.pumpWidget(
      BootHost(start: () => ready.future, look: SplashLook.android),
    );

    expect(find.byType(BootScreen), findsOneWidget);
    expect(find.text('The app'), findsNothing);

    ready.complete(app);
    await tester.pump();
    await tester.pump();
    expect(find.text('The app'), findsOneWidget);
    expect(find.byType(BootScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BootScreen), findsNothing);
    expect(find.text('The app'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('a quick start never shows a spinner; a slow one does', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final ready = Completer<Widget>();
    await tester.pumpWidget(BootHost(start: () => ready.future));

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(FluffySpinner), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(FluffySpinner), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.bySemanticsLabel('Starting Ferret…'), findsOneWidget);

    ready.complete(app);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FluffySpinner), findsNothing);
    await clear(tester);
    semantics.dispose();
  });

  testWidgets('a failed start says so, and Try again starts once more', (
    tester,
  ) async {
    var attempts = 0;
    final second = Completer<Widget>();
    await tester.pumpWidget(
      BootHost(
        start: () {
          attempts++;
          if (attempts == 1) {
            return Future.error(StateError('no keys'));
          }

          return second.future;
        },
        look: SplashLook.iOS,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text("Ferret couldn't start"), findsOneWidget);
    expect(find.byType(BootScreen), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
    // Still the same page while it tries, not the launch look again.
    expect(find.text("Ferret couldn't start"), findsOneWidget);

    await tester.tap(find.text('Try again'), warnIfMissed: false);
    await tester.pump();
    expect(attempts, 2);

    second.complete(app);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Ferret couldn't start"), findsNothing);
    expect(find.text('The app'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('taps reach the app as soon as it is there', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      BootHost(
        start: () async => GestureDetector(
          onTap: () => taps++,
          child: const ColoredBox(color: Color(0xFF000000)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(10, 10));
    expect(taps, 1, reason: 'the fading cover lets taps through');

    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(10, 10));
    expect(taps, 2);
    await clear(tester);
  });
}
