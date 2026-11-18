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

  /// Shows the app in the Dock and the app switcher, or hides it.
  void setShowsInDock(bool shows);

  /// Lets people drag the popover off into its own window.
  void setDetachable(bool detachable);

  /// Whether a drop where the pointer is now would be taken, so the cursor
  /// shows a copy badge or refuses.
  void setDropAllowed(bool allowed);

  /// Closes the popover if a file drag sprang it open.
  void closeIfOpenedByDrag();
}

@FlutterApi()
abstract class MenubarFlutterApi {
  void onMenuItemSelected(String id);

  void onPopoverVisibilityChanged(bool shown);

  /// Files dropped on the menubar icon.
  void onFilesDropped(List<String> paths);

  /// Files dragged into the popover, at [x], [y] in logical pixels from its
  /// top left.
  void onDragEntered(double x, double y, int fileCount);

  void onDragUpdated(double x, double y);

  /// The drag left the popover or was cancelled.
  void onDragExited();

  /// Files dropped on the popover at [x], [y].
  void onDragPerformed(List<String> paths, double x, double y);
}
