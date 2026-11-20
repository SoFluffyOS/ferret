import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
// The pigeon API is what a fake of the Mac side implements.
// ignore: implementation_imports
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  final SettingsStore settings = MemorySettingsStore();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifier implements LocalNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMenubarApi implements MenubarHostApi {
  final List<String?> registered = [];
  Completer<MenubarShortcut?> recording = Completer();
  bool refuses = false;

  @override
  Future<bool> setGlobalShortcut(MenubarShortcut? shortcut) async {
    registered.add(shortcut?.label);
    return !refuses;
  }

  final List<String?> clips = [];

  @override
  Future<bool> setClipsShortcut(MenubarShortcut? shortcut) async {
    clips.add(shortcut?.label);
    return !refuses;
  }

  @override
  Future<MenubarShortcut?> recordShortcut() => recording.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMenubarApi api;
  late _FakeEngine engine;

  /// The recording completes inside the test's own clock.
  Future<void> pump(
    WidgetTester tester, {
    Widget settings = const GlobalShortcutSettings(),
  }) async {
    api.recording = Completer();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(380, 560);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Provider<FerretMenubar>.value(
        value: FerretMenubar(api: api),
        child: ShellScope(
          features: const [],
          featureContext: FeatureContext(
            engine: engine,
            navigatorKey: GlobalKey<NavigatorState>(),
            notifier: _FakeNotifier(),
          ),
          child: testApp(settings),
        ),
      ),
    );
  }

  setUp(() {
    api = _FakeMenubarApi();
    engine = _FakeEngine();
  });

  testWidgets(
    'shows ⌃⌥Space, then the keys pressed after Change',
    (tester) async {
      await pump(tester);
      expect(find.text('⌃⌥Space'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pump();
      expect(find.text('Press the new keys. Esc cancels.'), findsOneWidget);

      api.recording.complete(
        MenubarShortcut(keyCode: 3, label: '⌘⇧F', command: true, shift: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('⌘⇧F'), findsOneWidget);
      expect(api.registered, ['⌘⇧F']);
      expect(GlobalShortcut.read(engine.settings)?.label, '⌘⇧F');
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'keys the Mac refuses leave the old ones, and say so',
    (tester) async {
      api.refuses = true;
      await pump(tester);

      await tester.tap(find.text('Change'));
      await tester.pump();
      api.recording.complete(MenubarShortcut(keyCode: 0, label: '⌘A'));
      await tester.pumpAndSettle();

      expect(find.text('⌃⌥Space'), findsOneWidget);
      expect(
        find.text("macOS didn't take these keys. Try others."),
        findsOneWidget,
      );
      expect(api.registered, ['⌘A', '⌃⌥Space']);
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('Turn off keeps it off', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    expect(find.text('Off'), findsOneWidget);
    expect(find.text('Turn on'), findsOneWidget);
    expect(GlobalShortcut.read(engine.settings), isNull);
  }, skip: !Platform.isMacOS);

  testWidgets('Recent clips keys show ⌃⌥V and turn off on their own', (
    tester,
  ) async {
    await pump(tester, settings: const GlobalShortcutSettings.clips());

    expect(find.text('Recent clips from anywhere'), findsOneWidget);
    expect(find.text('⌃⌥V'), findsOneWidget);

    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    expect(api.clips, [null]);
    expect(api.registered, isEmpty);
    expect(
      GlobalShortcut.read(
        engine.settings,
        key: GlobalShortcut.clipsKey,
        fallback: GlobalShortcut.recentClips,
      ),
      isNull,
    );
    expect(GlobalShortcut.read(engine.settings)?.label, '⌃⌥Space');
  });

  testWidgets('a screen reader hears which keys Change and Turn off are for', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, settings: const GlobalShortcutSettings.clips());

    expect(
      find.bySemanticsLabel('Change: Recent clips from anywhere'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Turn off: Recent clips from anywhere'),
      findsOneWidget,
    );
    semantics.dispose();
  }, skip: !Platform.isMacOS);
}
