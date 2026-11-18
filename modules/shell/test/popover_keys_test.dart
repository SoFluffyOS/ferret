import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';

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
}
