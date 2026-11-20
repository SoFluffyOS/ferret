import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

ActivityItem _line(
  String title, {
  VoidCallback? onTap,
  List<ActivityAction> actions = const [],
}) => ActivityItem(
  id: title,
  icon: LucideIcons.download,
  title: title,
  onTap: onTap,
  actions: actions,
);

void main() {
  final now = DateTime(2026, 11, 19, 12);

  Widget lines(List<Widget> children) => testApp(
    KeyboardLines(
      child: Column(mainAxisSize: .min, children: children),
    ),
  );

  Widget tapLine(
    String label, {
    required VoidCallback onTap,
    Map<SingleActivator, VoidCallback> keys = const {},
  }) => KeyboardLine(
    keys: keys,
    builder: (context, focusNode) => SurfaceCard(
      onTap: onTap,
      focusNode: focusNode,
      child: Text(label),
    ),
  );

  testWidgets('↓ and ↑ move from line to line, Enter opens the line', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      lines([
        tapLine('Pixel 9', onTap: () => opened.add('Pixel 9')),
        tapLine('iPad', onTap: () => opened.add('iPad')),
        ActivityRow(
          item: _line('Copied on Pixel 9', onTap: () => opened.add('clip')),
          now: now,
        ),
      ]),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(opened, ['iPad', 'clip', 'Pixel 9']);
  });

  testWidgets('Enter on a line that opens nothing runs its first action', (
    tester,
  ) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      lines([
        ActivityRow(
          item: _line(
            'IMG_2041.jpg from Pixel 9',
            actions: [
              ActivityAction(
                label: 'Open',
                onPressed: () => pressed.add('open'),
              ),
              ActivityAction(
                label: 'Show in Finder',
                onPressed: () => pressed.add('reveal'),
              ),
            ],
          ),
          now: now,
        ),
      ]),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(pressed, ['open']);
  });

  testWidgets('a line answers its own keys only while it has the focus', (
    tester,
  ) async {
    var sent = 0;
    const paste = SingleActivator(LogicalKeyboardKey.keyV, meta: true);
    await tester.pumpWidget(
      lines([
        tapLine('Pixel 9', onTap: () {}, keys: {paste: () => sent++}),
      ]),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(sent, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(sent, 1);
  });

  testWidgets('Esc in the popover goes back a page, then closes it', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var closed = 0;
    await tester.pumpWidget(
      WidgetsApp(
        navigatorKey: navigatorKey,
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: const Text('Home'),
        builder: (context, navigator) => PopoverKeysFrame(
          navigatorKey: navigatorKey,
          onClose: () => closed++,
          child: navigator ?? const SizedBox.shrink(),
        ),
      ),
    );
    unawaited(
      navigatorKey.currentState?.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const Text('Settings'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
    expect(closed, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, 1);
  });

  testWidgets('Home and End jump to the first and the last line', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      lines([
        for (final name in ['Pixel 9', 'iPad', 'Studio PC'])
          tapLine(name, onTap: () => opened.add(name)),
      ]),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(opened, ['Studio PC', 'Pixel 9']);
  });

  group('in the popover', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late FocusNode shelf;
    late List<String> opened;

    Future<void> showPopover(WidgetTester tester) async {
      navigatorKey = GlobalKey<NavigatorState>();
      shelf = FocusNode(debugLabel: 'shelf box');
      addTearDown(shelf.dispose);
      opened = [];
      await tester.pumpWidget(
        WidgetsApp(
          navigatorKey: navigatorKey,
          color: const Color(0xFFFFFFFF),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: KeyboardLines(
            child: Column(
              mainAxisSize: .min,
              children: [
                for (final name in ['Pixel 9', 'Studio PC'])
                  tapLine(name, onTap: () => opened.add(name)),
              ],
            ),
          ),
          builder: (context, navigator) => PopoverKeysFrame(
            navigatorKey: navigatorKey,
            onClose: () {},
            child: FluffyTheme(
              data: FluffyThemeData.fallback(),
              child: Column(
                children: [
                  Expanded(child: navigator ?? const SizedBox.shrink()),
                  Row(
                    children: [
                      const Focus(
                        debugLabel: 'Clear',
                        child: SizedBox(width: 40, height: 20),
                      ),
                      Expanded(
                        child: Focus(
                          focusNode: shelf,
                          child: const SizedBox(height: 100),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('↓ from the last device goes into the shelf, ↑ comes back', (
      tester,
    ) async {
      await showPopover(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(shelf.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(shelf.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(shelf.hasPrimaryFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(opened, ['Studio PC']);
    });

    testWidgets('↑ on the first device stays there', (tester) async {
      await showPopover(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(opened, ['Pixel 9']);
    });
  });
}
