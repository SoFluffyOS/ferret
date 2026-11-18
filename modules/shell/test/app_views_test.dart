import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
// The pigeon API is what a fake of the Mac side implements.
// ignore: implementation_imports
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

class _FakeMenubarApi implements MenubarHostApi {
  _FakeMenubarApi(this.windowViewId);

  final int windowViewId;
  final List<MenubarDockMode> dockModes = [];
  int popoverShown = 0;
  int windowOpened = 0;

  @override
  Future<bool> isWindowSupported() async => true;

  @override
  Future<bool> isWindowOpen() async => false;

  @override
  Future<int> openWindow() async {
    windowOpened++;
    return windowViewId;
  }

  @override
  Future<void> setDockMode(MenubarDockMode mode) async => dockModes.add(mode);

  @override
  Future<void> showPopover() async => popoverShown++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMenubarApi api;
  late FerretMenubar menubar;
  late MemorySettingsStore settings;
  late AppViews views;

  Future<void> start(WidgetTester tester) async {
    api = _FakeMenubarApi(tester.view.viewId);
    menubar = FerretMenubar(api: api);
    settings = MemorySettingsStore();
    views = AppViews(menubar: menubar, settings: settings);
    addTearDown(views.dispose);
    await views.start();
  }

  testWidgets('before the window opens everything goes to the popover', (
    tester,
  ) async {
    await start(tester);

    expect(views.canOpenWindow, isTrue);
    expect(views.isWindowOpen, isFalse);
    expect(views.activeNavigatorKey, views.mainNavigatorKey);

    await views.reveal();
    expect(api.popoverShown, 1);
  }, skip: !Platform.isMacOS);

  testWidgets('an open window is the active view, until the popover is in '
      'front of it', (tester) async {
    await start(tester);
    var changes = 0;
    views.addListener(() => changes++);

    await views.openWindow();
    expect(views.isWindowOpen, isTrue);
    expect(views.window?.viewId, tester.view.viewId);
    expect(changes, 1);
    expect(views.activeNavigatorKey, views.windowNavigatorKey);

    menubar
      ..onWindowFocusChanged(false)
      ..onPopoverVisibilityChanged(true);
    await tester.pump();
    expect(views.activeNavigatorKey, views.mainNavigatorKey);

    menubar.onWindowFocusChanged(true);
    await tester.pump();
    expect(views.activeNavigatorKey, views.windowNavigatorKey);
  }, skip: !Platform.isMacOS);

  testWidgets('revealing brings the open window forward, not the popover', (
    tester,
  ) async {
    await start(tester);
    await views.openWindow();

    await views.reveal();

    expect(api.windowOpened, 2);
    expect(api.popoverShown, 0);
  }, skip: !Platform.isMacOS);

  testWidgets('closing the window goes back to the popover, and the next '
      'window starts with a new navigator', (tester) async {
    await start(tester);
    await views.openWindow();
    final firstKey = views.windowNavigatorKey;

    menubar.onWindowClosed(tester.view.viewId);
    await tester.pump();
    expect(views.isWindowOpen, isFalse);
    expect(views.activeNavigatorKey, views.mainNavigatorKey);

    await views.openWindow();
    expect(views.isWindowOpen, isTrue);
    expect(views.windowNavigatorKey, isNot(firstKey));
  }, skip: !Platform.isMacOS);

  testWidgets('the Dock setting is kept and reaches the Mac', (tester) async {
    await start(tester);
    expect(views.alwaysInDock, isFalse);

    await views.setAlwaysInDock(true);

    expect(views.alwaysInDock, isTrue);
    expect(settings.get<String>(AppViews.dockModeKey), 'always');
    expect(api.dockModes, [
      MenubarDockMode.whenWindowOpen,
      MenubarDockMode.always,
    ]);
  }, skip: !Platform.isMacOS);
}
