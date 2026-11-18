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

@HostApi()
abstract class MenubarHostApi {
  /// Shows an SF Symbol as the menubar icon, drawn as a template image.
  void setIcon(String symbolName, String? tooltip);

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
