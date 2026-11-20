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

/// A file that isn't on this Mac yet, such as a photo on a phone: dragged
/// out, the app it lands on asks for it, and only then is it fetched.
class MenubarPromisedFile {
  MenubarPromisedFile({required this.id, required this.name, this.image});

  /// What [MenubarFlutterApi.onPromisedFileWanted] asks for.
  String id;

  /// The file's name where it lands, such as "IMG_2041.jpg".
  String name;

  /// A picture of it to drag, such as a thumbnail; the icon of its type
  /// when null.
  Uint8List? image;
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

/// A screen in global screen points, y going up from the bottom of the
/// main screen: all of it, and what the menu bar and Dock leave.
class MenubarScreen {
  MenubarScreen({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.visibleX,
    required this.visibleY,
    required this.visibleWidth,
    required this.visibleHeight,
  });

  double x;
  double y;
  double width;
  double height;
  double visibleX;
  double visibleY;
  double visibleWidth;
  double visibleHeight;
}

/// Where a drag in another app is, and the keys held with it.
class MenubarDragPoint {
  MenubarDragPoint({
    required this.x,
    required this.y,
    required this.screen,
    required this.fn,
    required this.shift,
  });

  double x;
  double y;

  /// The screen under the pointer.
  MenubarScreen screen;
  bool fn;
  bool shift;
}

/// A drag that started in another app: what it carries by its types
/// alone, and the app it started in.
class MenubarSystemDrag {
  MenubarSystemDrag({required this.kind, required this.point, this.sourceApp});

  MenubarDragKind kind;
  MenubarDragPoint point;

  /// The bundle id of the app in front when the drag started.
  String? sourceApp;
}

/// An app that runs now, to pick from.
class MenubarApp {
  MenubarApp({required this.bundleId, required this.name});

  String bundleId;
  String name;
}

/// How the floating panel comes in and goes out. With Reduce Motion on,
/// it fades.
enum MenubarPanelMotion { fromRight, fromLeft, inPlace }

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
  /// front; another [id] takes its place. A [barHeight] above zero adds a
  /// bar that many points tall along the top edge, under the traffic
  /// lights, where Flutter draws its controls: the picture keeps its shape
  /// below it. With [fullScreen], the window fills its screen at once, as
  /// a display does.
  int openPictureWindow(
    String id,
    String title,
    double width,
    double height,
    double barHeight,
    bool fullScreen,
  );

  /// The picture is [width] by [height] pixels now, such as after the
  /// phone was turned: the window turns with it and keeps its long side.
  void setPictureWindowSize(double width, double height);

  void focusPictureWindow();

  /// Moves the picture window with the pointer, from a press on its bar.
  void dragPictureWindow();

  /// Closes the picture window and removes its Flutter view.
  void closePictureWindow();

  /// Puts the picture window in full screen, or takes it out.
  void setPictureWindowFullScreen(bool fullScreen);

  bool isPictureWindowFullScreen();

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

  /// A second combination that shows Recent clips from anywhere. False when
  /// the Mac refused it.
  bool setClipsShortcut(MenubarShortcut? shortcut);

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

  /// Starts dragging [files] that aren't here yet out of the view
  /// [viewId], like [startFileDrag]. Where they land, each is asked for
  /// with [MenubarFlutterApi.onPromisedFileWanted] and copied there.
  bool startPromisedFileDrag(int viewId, List<MenubarPromisedFile> files);

  /// Starts dragging [text] out of the view [viewId], like
  /// [startFileDrag]: plain text, and a web link as well when [isLink].
  bool startTextDrag(int viewId, String text, bool isLink);

  /// Shows the files at [paths] in Quick Look, or closes it when it is
  /// open.
  void toggleQuickLook(List<String> paths);

  /// Starts or stops watching drags in other apps. Mouse events and the
  /// drag pasteboard's types only, so the Mac asks for no permission.
  void watchSystemDrags(bool on);

  /// How a drag over the menubar icon opens the popover: after resting
  /// there for the Mac's spring-loading delay when [springOnHover], at
  /// once when [opensAtOnce].
  void setIconDragBehavior(bool springOnHover, bool opensAtOnce);

  /// What a small label under the icon says while a drag of files, or of
  /// text and links, rests on it, such as "Send to Pixel 7". Null shows
  /// none.
  void setIconDropLabels(String? files, String? text);

  /// A small notice under the icon for [seconds], with a button that says
  /// [action] when there is one, such as Undo.
  void showIconNotice(String text, String? action, double seconds);

  void hideIconNotice();

  /// Shows the floating panel at [x], [y] (its bottom left in global
  /// screen points) and [width] by [height], over every app and Space,
  /// without taking focus. Returns the id of its Flutter view.
  int showFloatingPanel(
    double x,
    double y,
    double width,
    double height,
    double radius,
    MenubarPanelMotion motion,
  );

  void hideFloatingPanel();

  /// The apps that run now with a window or a Dock icon.
  List<MenubarApp> runningApps();
}

@FlutterApi()
abstract class MenubarFlutterApi {
  void onMenuItemSelected(String id);

  /// The Recent clips combination was pressed.
  void onClipsShortcut();

  void onPopoverVisibilityChanged(bool shown);

  /// Files dropped on the menubar icon.
  void onFilesDropped(List<String> paths);

  /// Something of [kind] dragged into the view [viewId] (the popover's or
  /// the window's), at [x], [y] in logical pixels from its top left.
  /// [fileCount] is 1 for text and links. [fromApp] when the drag started
  /// in this app, such as an item dragged off the shelf.
  void onDragEntered(
    int viewId,
    double x,
    double y,
    int fileCount,
    MenubarDragKind kind,
    bool fromApp,
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

  /// A drag started in another app. Ferret's own drags never show here.
  void onSystemDragStarted(MenubarSystemDrag drag);

  void onSystemDragMoved(MenubarDragPoint point);

  void onSystemDragEnded();

  /// Text, or a link when [isLink], dropped on the menubar icon.
  void onIconTextDropped(String text, bool isLink);

  /// The button on the icon's notice was pressed.
  void onIconNoticeAction();

  /// A promised file [id] was dropped: the path of a local copy to copy
  /// where it landed, once there is one, or null when it couldn't be had.
  @async
  String? onPromisedFileWanted(String id);
}
