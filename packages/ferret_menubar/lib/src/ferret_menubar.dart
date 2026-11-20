import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ferret_menubar/src/messages.g.dart';
import 'package:ferret_menubar/src/popover_drag.dart';
import 'package:ferret_menubar/src/system_drag.dart';
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
  final StreamController<void> _clipsShortcut = .broadcast();
  final StreamController<bool> _visibility = .broadcast();
  final StreamController<List<String>> _drops = .broadcast();
  final StreamController<PopoverDrag> _drags = .broadcast();
  final StreamController<MenubarWindowEvent> _windowEvents = .broadcast();
  final StreamController<int> _pictureWindowClosed = .broadcast();
  final StreamController<MenubarSystemDragEvent> _systemDrags = .broadcast();
  final StreamController<(String, bool)> _iconTextDrops = .broadcast();
  final StreamController<void> _noticeActions = .broadcast();

  /// How each promised file still out on a drag is fetched, by its id.
  final Map<String, Future<String?> Function()> _promises = {};
  var _promiseCount = 0;

  bool get isSupported => Platform.isMacOS;

  /// Ids of menu items people pick.
  Stream<String> get menuSelections => _menuSelections.stream;

  /// Fires when the Recent clips combination is pressed, in any app.
  Stream<void> get clipsShortcutPresses => _clipsShortcut.stream;

  /// Whether the popover is showing, each time it changes.
  Stream<bool> get visibility => _visibility.stream;

  /// Paths of files dropped on the menubar icon.
  Stream<List<String>> get drops => _drops.stream;

  /// Text, and whether it is a link, dropped on the menubar icon.
  Stream<(String, bool)> get iconTextDrops => _iconTextDrops.stream;

  /// The button on the icon's notice, such as Undo, was pressed.
  Stream<void> get noticeActions => _noticeActions.stream;

  /// Drags in other apps, while [watchSystemDrags] is on.
  Stream<MenubarSystemDragEvent> get systemDrags => _systemDrags.stream;

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
  /// view, or null where there is no such window. A [barHeight] adds a
  /// bar that many points tall along the top edge, beside the traffic
  /// lights, for controls that must never cover the picture. With
  /// [fullScreen] it fills its screen at once.
  Future<int?> openPictureWindow({
    required String id,
    required String title,
    required Size size,
    double barHeight = 0,
    bool fullScreen = false,
  }) async {
    if (!await isWindowSupported()) {
      return null;
    }

    return _api.openPictureWindow(
      id,
      title,
      size.width,
      size.height,
      barHeight,
      fullScreen,
    );
  }

  /// The picture has [size] pixels now, such as after the phone was
  /// turned: the window turns with it and keeps its long side.
  Future<void> setPictureWindowSize(Size size) =>
      _call(() => _api.setPictureWindowSize(size.width, size.height));

  Future<void> focusPictureWindow() => _call(_api.focusPictureWindow);

  /// Moves the picture window with the pointer, from a press on its bar.
  Future<void> dragPictureWindow() => _call(_api.dragPictureWindow);

  /// Closes the picture window and removes its Flutter view.
  Future<void> closePictureWindow() => _call(_api.closePictureWindow);

  /// Puts the picture window in full screen, or takes it out.
  Future<void> setPictureWindowFullScreen(bool fullScreen) =>
      _call(() => _api.setPictureWindowFullScreen(fullScreen));

  Future<bool> isPictureWindowFullScreen() async {
    try {
      return await _api.isPictureWindowFullScreen();
    } on Object {
      return false;
    }
  }

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

  /// Shows Recent clips with [shortcut] from any app, or stops when it is
  /// null. A second Carbon hot key, like [setGlobalShortcut].
  Future<bool> setClipsShortcut(MenubarShortcut? shortcut) async {
    if (!isSupported) {
      return false;
    }

    return _api.setClipsShortcut(shortcut);
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

  /// Drags the files at [paths] out of the view [viewId] to Finder or
  /// another app, from the mouse press under way there: call it when a
  /// drag starts on something that stands for those files. False when it
  /// couldn't start, or where there is no menubar.
  Future<bool> startFileDrag(int viewId, List<String> paths) async {
    if (!isSupported) {
      return false;
    }

    return _api.startFileDrag(viewId, paths);
  }

  /// Drags files that aren't on this Mac yet out of the view [viewId],
  /// like [startFileDrag]. Each is a name, a picture to drag, and how to
  /// get a local copy: that runs only once the file is dropped somewhere,
  /// and the copy is then copied there. False when it couldn't start.
  Future<bool> startPromisedFileDrag(
    int viewId,
    List<PromisedDragFile> files,
  ) async {
    if (!isSupported || files.isEmpty) {
      return false;
    }

    final promised = [
      for (final file in files)
        MenubarPromisedFile(
          id: _promise(file.fetch),
          name: file.name,
          image: file.image,
        ),
    ];
    final started = await _api.startPromisedFileDrag(viewId, promised);
    if (!started) {
      for (final file in promised) {
        _promises.remove(file.id);
      }
    }

    return started;
  }

  /// Drags [text] out of the view [viewId] to another app, like
  /// [startFileDrag]; a link goes as a web address too. False when it
  /// couldn't start, or where there is no menubar.
  Future<bool> startTextDrag(
    int viewId,
    String text, {
    bool isLink = false,
  }) async {
    if (!isSupported || text.isEmpty) {
      return false;
    }

    return _api.startTextDrag(viewId, text, isLink);
  }

  String _promise(Future<String?> Function() fetch) {
    // A drag cancelled before it landed never asks: keep only the latest.
    if (_promises.length >= _keptPromises) {
      _promises.remove(_promises.keys.first);
    }

    final id = 'promise.${++_promiseCount}';
    _promises[id] = fetch;
    return id;
  }

  static const _keptPromises = 64;

  /// Shows the files at [paths] in Quick Look, or closes it when open.
  Future<void> toggleQuickLook(List<String> paths) =>
      _call(() => _api.toggleQuickLook(paths));

  /// Starts or stops watching drags in other apps, for [systemDrags]. It
  /// asks for no permission: mouse events and the drag's types only.
  Future<void> watchSystemDrags({required bool on}) =>
      _call(() => _api.watchSystemDrags(on));

  /// How a drag over the icon opens the popover: after the Mac's own
  /// spring-loading delay when [springOnHover], at once when [opensAtOnce].
  Future<void> setIconDragBehavior({
    required bool springOnHover,
    required bool opensAtOnce,
  }) => _call(() => _api.setIconDragBehavior(springOnHover, opensAtOnce));

  /// What the label under the icon says while a drag of [files], or of
  /// [text] and links, rests on it. Null shows none.
  Future<void> setIconDropLabels({String? files, String? text}) =>
      _call(() => _api.setIconDropLabels(files, text));

  /// A small notice under the icon for [duration], with a button when
  /// [action] is set; [noticeActions] hears it pressed.
  Future<void> showIconNotice(
    String text, {
    String? action,
    Duration duration = const Duration(seconds: 2),
  }) => _call(
    () => _api.showIconNotice(
      text,
      action,
      duration.inMilliseconds / Duration.millisecondsPerSecond,
    ),
  );

  Future<void> hideIconNotice() => _call(_api.hideIconNotice);

  /// Shows the floating panel at [frame] (global screen points, y up),
  /// over every app and Space, without taking focus. Gives the id of its
  /// Flutter view, or null where there is none.
  Future<int?> showFloatingPanel(
    Rect frame, {
    required double radius,
    required MenubarPanelMotion motion,
  }) async {
    if (!isSupported || !await isWindowSupported()) {
      return null;
    }

    return _api.showFloatingPanel(
      frame.left,
      frame.top,
      frame.width,
      frame.height,
      radius,
      motion,
    );
  }

  Future<void> hideFloatingPanel() => _call(_api.hideFloatingPanel);

  /// The apps running now with a window or a Dock icon, by name.
  Future<List<MenubarApp>> runningApps() async {
    if (!isSupported) {
      return const [];
    }

    return _api.runningApps();
  }

  Future<void> _call(Future<void> Function() call) async {
    if (!isSupported) {
      return;
    }

    await call();
  }

  @override
  void onMenuItemSelected(String id) => _menuSelections.add(id);

  @override
  void onClipsShortcut() => _clipsShortcut.add(null);

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
    bool fromApp,
  ) => _drags.add(
    PopoverDragEntered(
      viewId,
      Offset(x, y),
      fileCount,
      kind: kind,
      fromApp: fromApp,
    ),
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

  @override
  void onSystemDragStarted(MenubarSystemDrag drag) =>
      _systemDrags.add(MenubarSystemDragStarted(drag));

  @override
  void onSystemDragMoved(MenubarDragPoint point) =>
      _systemDrags.add(MenubarSystemDragMoved(point));

  @override
  void onSystemDragEnded() => _systemDrags.add(const MenubarSystemDragEnded());

  @override
  void onIconTextDropped(String text, bool isLink) =>
      _iconTextDrops.add((text, isLink));

  @override
  void onIconNoticeAction() => _noticeActions.add(null);

  @override
  Future<String?> onPromisedFileWanted(String id) async {
    final fetch = _promises.remove(id);
    if (fetch == null) {
      return null;
    }

    try {
      return await fetch();
    } on Object {
      return null;
    }
  }
}

/// A file to drag out that is fetched only once it is dropped, such as a
/// photo still on a phone.
class PromisedDragFile {
  const PromisedDragFile({required this.name, required this.fetch, this.image});

  /// Its name where it lands, such as "IMG_2041.jpg".
  final String name;

  /// A picture to drag, such as a thumbnail.
  final Uint8List? image;

  /// The path of a local copy, or null when there is none to be had.
  final Future<String?> Function() fetch;
}
