import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ferret_menubar/src/messages.g.dart';
import 'package:ferret_menubar/src/popover_drag.dart';
import 'package:ferret_menubar/src/window_event.dart';

/// The menubar icon, its popover and the desktop window on macOS. Elsewhere
/// every call does nothing and [isSupported] is false.
class FerretMenubar implements MenubarFlutterApi {
  FerretMenubar({MenubarHostApi? api}) : _api = api ?? MenubarHostApi() {
    if (isSupported) {
      MenubarFlutterApi.setUp(this);
    }
  }

  final MenubarHostApi _api;
  final StreamController<String> _menuSelections = .broadcast();
  final StreamController<bool> _visibility = .broadcast();
  final StreamController<List<String>> _drops = .broadcast();
  final StreamController<PopoverDrag> _drags = .broadcast();
  final StreamController<MenubarWindowEvent> _windowEvents = .broadcast();
  final StreamController<int> _pictureWindowClosed = .broadcast();

  bool get isSupported => Platform.isMacOS;

  /// Ids of menu items people pick.
  Stream<String> get menuSelections => _menuSelections.stream;

  /// Whether the popover is showing, each time it changes.
  Stream<bool> get visibility => _visibility.stream;

  /// Paths of files dropped on the menubar icon.
  Stream<List<String>> get drops => _drops.stream;

  /// Files, text and links dragged over and dropped on the popover (docked
  /// or detached) or the desktop window; each event names its view.
  Stream<PopoverDrag> get drags => _drags.stream;

  /// The desktop window opening, taking or losing the keyboard, and closing.
  Stream<MenubarWindowEvent> get windowEvents => _windowEvents.stream;

  /// The picture window closing: the id of the Flutter view that is gone.
  Stream<int> get pictureWindowClosed => _pictureWindowClosed.stream;

  /// Draws the icon for [state]. [progress], 0 to 1, fills the ring of
  /// [MenubarIconState.working]. A file drag over the icon shows
  /// [MenubarIconState.dragOver] by itself, then this state again.
  Future<void> setIconState(
    MenubarIconState state, {
    double progress = 0,
    String tooltip = 'Ferret',
  }) => _call(
    () => _api.setIconState(state, progress.clamp(0, 1).toDouble(), tooltip),
  );

  Future<void> setPopoverSize(double width, double height) =>
      _call(() => _api.setPopoverSize(width, height));

  Future<void> show() => _call(_api.showPopover);

  Future<void> hide() => _call(_api.hidePopover);

  Future<void> setMenu(List<MenubarMenuItem> items) =>
      _call(() => _api.setMenu(items));

  /// When the app shows in the Dock: only while the desktop window is open
  /// (the default), or always.
  Future<void> setDockMode(MenubarDockMode mode) =>
      _call(() => _api.setDockMode(mode));

  /// Whether the desktop window can open here. It draws a second Flutter
  /// view on the same engine, so the app's state is the popover's.
  Future<bool> isWindowSupported() async {
    if (!isSupported) {
      return false;
    }

    return _api.isWindowSupported();
  }

  /// Opens the desktop window next to the popover, or brings it to the
  /// front when it is open already. Gives the id of its Flutter view, or
  /// null where there is no such window. Draw into it with a `View` once
  /// `PlatformDispatcher.views` holds it.
  Future<int?> openWindow() async {
    if (!await isWindowSupported()) {
      return null;
    }

    return _api.openWindow();
  }

  /// Closes the desktop window and removes its Flutter view. The app keeps
  /// running in the menubar.
  Future<void> closeWindow() => _call(_api.closeWindow);

  Future<bool> isWindowOpen() async {
    if (!isSupported) {
      return false;
    }

    return _api.isWindowOpen();
  }

  /// Names the desktop window after what it shows, such as
  /// "Pixel 9 — Messages".
  Future<void> setWindowTitle(String title) =>
      _call(() => _api.setWindowTitle(title));

  /// Opens a window in the shape of a picture of [size] pixels, such as a
  /// phone's screen, next to the popover and the desktop window. It keeps
  /// that shape while it is resized, and gets back the size and place it
  /// had for [id]. Asked again for the [id] that is open, it comes to the
  /// front; another [id] takes its place. Gives the id of its Flutter
  /// view, or null where there is no such window.
  Future<int?> openPictureWindow({
    required String id,
    required String title,
    required Size size,
  }) async {
    if (!await isWindowSupported()) {
      return null;
    }

    return _api.openPictureWindow(id, title, size.width, size.height);
  }

  /// The picture has [size] pixels now, such as after the phone was
  /// turned: the window turns with it and keeps its long side.
  Future<void> setPictureWindowSize(Size size) =>
      _call(() => _api.setPictureWindowSize(size.width, size.height));

  Future<void> focusPictureWindow() => _call(_api.focusPictureWindow);

  /// Closes the picture window and removes its Flutter view.
  Future<void> closePictureWindow() => _call(_api.closePictureWindow);

  Future<void> setDetachable(bool detachable) =>
      _call(() => _api.setDetachable(detachable));

  /// Says whether a drop where the pointer is now, over the view [viewId],
  /// would be taken.
  Future<void> setDropAllowed(int viewId, {required bool allowed}) =>
      _call(() => _api.setDropAllowed(viewId, allowed));

  /// Closes the popover if a file drag over the icon sprang it open.
  Future<void> closeIfOpenedByDrag() => _call(_api.closeIfOpenedByDrag);

  /// Opens or closes the popover with [shortcut] from any app, or stops
  /// doing so when it is null. It is a Carbon hot key: it hears only its
  /// own keys, so macOS asks for no Accessibility access. False when the
  /// Mac refused it, or where there is no menubar.
  Future<bool> setGlobalShortcut(MenubarShortcut? shortcut) async {
    if (!isSupported) {
      return false;
    }

    return _api.setGlobalShortcut(shortcut);
  }

  /// The next key with a modifier (⌘, ⌃ or ⌥; F-keys alone) pressed in
  /// the app, for a new global shortcut. Null when Esc was pressed, it was
  /// [cancelRecording]-ed, or where there is no menubar.
  Future<MenubarShortcut?> recordShortcut() async {
    if (!isSupported) {
      return null;
    }

    return _api.recordShortcut();
  }

  Future<void> cancelRecording() => _call(_api.cancelRecording);

  Future<void> _call(Future<void> Function() call) async {
    if (!isSupported) {
      return;
    }

    await call();
  }

  @override
  void onMenuItemSelected(String id) => _menuSelections.add(id);

  @override
  void onPopoverVisibilityChanged(bool shown) => _visibility.add(shown);

  @override
  void onFilesDropped(List<String> paths) => _drops.add(paths);

  @override
  void onDragEntered(
    int viewId,
    double x,
    double y,
    int fileCount,
    MenubarDragKind kind,
  ) => _drags.add(
    PopoverDragEntered(viewId, Offset(x, y), fileCount, kind: kind),
  );

  @override
  void onDragUpdated(int viewId, double x, double y) =>
      _drags.add(PopoverDragMoved(viewId, Offset(x, y)));

  @override
  void onDragExited(int viewId) => _drags.add(PopoverDragExited(viewId));

  @override
  void onDragPerformed(int viewId, List<String> paths, double x, double y) =>
      _drags.add(PopoverDragDropped(viewId, paths, Offset(x, y)));

  @override
  void onTextDropped(
    int viewId,
    String text,
    bool isLink,
    double x,
    double y,
  ) => _drags.add(
    PopoverTextDropped(viewId, text, Offset(x, y), isLink: isLink),
  );

  @override
  void onWindowOpened(int viewId) =>
      _windowEvents.add(MenubarWindowOpened(viewId));

  @override
  void onWindowFocusChanged(bool focused) =>
      _windowEvents.add(MenubarWindowFocusChanged(focused: focused));

  @override
  void onWindowClosed(int viewId) =>
      _windowEvents.add(MenubarWindowClosed(viewId));

  @override
  void onPictureWindowClosed(int viewId) => _pictureWindowClosed.add(viewId);
}
