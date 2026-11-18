import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

void main() {
  group('keys are written the way the computer writes them', () {
    String describe(WindowCommand command, TargetPlatform platform) {
      final key = WindowShortcuts.activatorOf(command, platform);
      if (key == null) {
        return '';
      }

      return WindowShortcuts.describe(key, platform);
    }

    test('Windows and Linux', () {
      expect(describe(.sendClipboard, .linux), 'Ctrl+Shift+V');
      expect(describe(.toggleSidebar, .linux), 'F9');
      expect(describe(.toggleSidebar, .windows), 'Ctrl+B');
      expect(describe(.nextDevice, .windows), 'Ctrl+Alt+↓');
      expect(describe(.openSettings, .linux), 'Ctrl+,');
      expect(describe(.showShortcuts, .linux), 'Ctrl+?');
      expect(describe(.quit, .windows), 'Ctrl+Q');
    });

    test('a Mac', () {
      expect(describe(.sendClipboard, .macOS), '⇧⌘V');
      expect(describe(.toggleSidebar, .macOS), '⌃⌘S');
      expect(describe(.quit, .macOS), '');
    });
  });

  testWidgets('on Linux the ••• menu shows each command with its keys, '
      'and skips what cannot apply', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picked = <WindowCommand>[];
    final commands = WindowCommands({
      for (final command in WindowCommand.values)
        command: switch (command) {
          .fixConnection || .sendFiles => null,
          _ => () => picked.add(command),
        },
    });

    await tester.pumpWidget(
      testApp(
        Provider<WindowCommands?>.value(
          value: commands,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => const Align(
                  alignment: Alignment.topLeft,
                  child: WindowMoreMenu(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();

    expect(find.text('Add a Device…'), findsOneWidget);
    expect(find.text('Ctrl+N'), findsOneWidget);
    expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    expect(find.text('Ctrl+?'), findsOneWidget);
    expect(find.text('Quit Ferret'), findsOneWidget);
    expect(find.text('Send Files…'), findsNothing);
    expect(find.text('Fix Connection…'), findsNothing);

    await tester.tap(find.text('Quit Ferret'));
    await tester.pumpAndSettle();
    expect(picked, [WindowCommand.quit]);
  });

  testWidgets('the shortcuts page lists every key', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(testApp(const KeyboardShortcutsPage()));

    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(find.text('Ctrl+1 … Ctrl+6'), findsOneWidget);
    expect(find.text('Ctrl+B'), findsOneWidget);
    expect(find.text('Ctrl+Q'), findsOneWidget);
    expect(find.text('Send Clipboard'), findsOneWidget);
  });
}
