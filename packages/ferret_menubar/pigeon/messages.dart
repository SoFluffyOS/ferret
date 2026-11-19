import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_menubar',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'macos/ferret_menubar/Sources/ferret_menubar/Messages.g.swift',
  ),
)
class MenubarMenuItem {
  MenubarMenuItem({
    required this.id,
    required this.title,
    this.enabled = true,
    this.separator = false,
    this.keyEquivalent,
  });

  String id;
  String title;
  bool enabled;
  bool separator;
  String? keyEquivalent;
}

/// A key with its modifiers, pressed anywhere on the Mac.
class MenubarShortcut {
  MenubarShortcut({
    required this.keyCode,
    required this.label,
    this.command = false,
    this.control = false,
    this.option = false,
    this.shift = false,
  });

  /// The Mac's virtual key code (`kVK_*`), the same on every layout.
  int keyCode;

  /// How it reads, such as "⌃⌥Space".
  String label;
  bool command;
  bool control;
  bool option;
  bool shift;
}

/// What the menubar icon says, one at a time.
enum MenubarIconState {
  /// At least one device is connected: the plain glyph.
  normal,

  /// Nothing is connected, which is no error: the glyph, dimmed.
  alone,

  /// A file drag is over the icon. The icon shows this by itself while the
  /// drag is there, then goes back to the state it was given.
  dragOver,

  /// A transfer is running: the glyph in a progress ring.
  working,

  /// A transfer just finished: a check.
  done,

  /// A pairing or file request waits for the person: the glyph with a dot.
  needsYou,

  /// Ferret is paused: the glyph, slashed.
  paused,
}

/// What is dragged over one of the app's views.
enum MenubarDragKind {
  /// Files, from Finder or promised by an app such as Photos.
  files,

  /// Text, such as words selected on a web page.
  text,

  /// A web link, such as one dragged from a browser's address bar.
  link,
}

/// When the app shows in the Dock and the app switcher.
enum MenubarDockMode {
  /// Only while the desktop window is open.
  whenWindowOpen,

  /// All the time, like a regular app.
  always,
}

@HostApi()
abstract class MenubarHostApi {
  /// Draws the menubar icon for [state]. [progress] is 0 to 1 and fills the
  /// ring of [MenubarIconState.working]; [tooltip] shows when the pointer
  /// rests on the icon.
  void setIconState(MenubarIconState state, double progress, String tooltip);

  void setPopoverSize(double width, double height);

  void showPopover();

  void hidePopover();

  bool isPopoverShown();

  /// The menu a right-click (or Control-click) on the icon opens.
  void setMenu(List<MenubarMenuItem> items);

  /// When the app shows in the Dock and the app switcher.
  void setDockMode(MenubarDockMode mode);

  /// Whether this Flutter can draw a second view, which the desktop window
  /// needs. False leaves the app in its popover only.
  bool isWindowSupported();

  /// Opens the desktop window next to the popover, or brings it to the
  /// front when it is open already. Returns the id of its Flutter view.
  int openWindow();

  /// Closes the desktop window and removes its Flutter view. The app keeps
  /// running in the menubar.
  void closeWindow();

  bool isWindowOpen();

  /// What the desktop window's title bar says, such as the device and the
  /// section it shows.
  void setWindowTitle(String title);

  /// Opens a window in the shape of a picture [width] by [height] pixels,
  /// such as a phone's screen, and returns the id of its Flutter view. It
  /// keeps that shape while it is resized and remembers its size and place
  /// for each [id]. Asked again for the [id] that is open, it comes to the
  /// front; another [id] takes its place.
  int openPictureWindow(String id, String title, double width, double height);

  /// The picture is [width] by [height] pixels now, such as after the
  /// phone was turned: the window turns with it and keeps its long side.
  void setPictureWindowSize(double width, double height);

  void focusPictureWindow();

  /// Closes the picture window and removes its Flutter view.
  void closePictureWindow();

  /// Lets people drag the popover off into its own window.
  void setDetachable(bool detachable);

  /// Whether a drop where the pointer is now, over the view [viewId], would
  /// be taken, so the cursor shows a copy badge or refuses.
  void setDropAllowed(int viewId, bool allowed);

  /// Closes the popover if a file drag sprang it open.
  void closeIfOpenedByDrag();

  /// Opens or closes the popover with [shortcut] from any app, or stops
  /// doing so when it is null. False when the Mac refused it.
  bool setGlobalShortcut(MenubarShortcut? shortcut);

  /// The next key with a modifier pressed in the app, for a new global
  /// shortcut; null when Esc was pressed or it was cancelled. The global
  /// shortcut rests meanwhile, so pressing it records it.
  @async
  MenubarShortcut? recordShortcut();

  void cancelRecording();

  /// Starts dragging the files at [paths] out of the view [viewId], from
  /// where the mouse is pressed in it, to Finder or another app. False
  /// when no press in that view is under way.
  bool startFileDrag(int viewId, List<String> paths);

  /// Shows the files at [paths] in Quick Look, or closes it when it is
  /// open.
  void toggleQuickLook(List<String> paths);
}

@FlutterApi()
abstract class MenubarFlutterApi {
  void onMenuItemSelected(String id);

  void onPopoverVisibilityChanged(bool shown);

  /// Files dropped on the menubar icon.
  void onFilesDropped(List<String> paths);

  /// Something of [kind] dragged into the view [viewId] (the popover's or
  /// the window's), at [x], [y] in logical pixels from its top left.
  /// [fileCount] is 1 for text and links.
  void onDragEntered(
    int viewId,
    double x,
    double y,
    int fileCount,
    MenubarDragKind kind,
  );

  void onDragUpdated(int viewId, double x, double y);

  /// The drag left the view or was cancelled.
  void onDragExited(int viewId);

  /// Files dropped on the view at [x], [y].
  void onDragPerformed(int viewId, List<String> paths, double x, double y);

  /// Text, or a link when [isLink], dropped on the view at [x], [y].
  void onTextDropped(int viewId, String text, bool isLink, double x, double y);

  /// The desktop window opened, drawing the Flutter view [viewId].
  void onWindowOpened(int viewId);

  /// The desktop window became the one that takes the keyboard, or stopped
  /// being it.
  void onWindowFocusChanged(bool focused);

  /// The desktop window closed and its Flutter view [viewId] is gone.
  void onWindowClosed(int viewId);

  /// The picture window closed and its Flutter view [viewId] is gone.
  void onPictureWindowClosed(int viewId);
}
