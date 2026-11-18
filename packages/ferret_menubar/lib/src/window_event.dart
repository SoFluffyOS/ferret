/// Something that happened to the desktop window.
sealed class MenubarWindowEvent {
  const MenubarWindowEvent();
}

/// The window opened. It draws the Flutter view [viewId], which
/// `PlatformDispatcher.views` now holds.
final class MenubarWindowOpened extends MenubarWindowEvent {
  const MenubarWindowOpened(this.viewId);

  final int viewId;
}

/// The window started or stopped being the one that takes the keyboard.
final class MenubarWindowFocusChanged extends MenubarWindowEvent {
  const MenubarWindowFocusChanged({required this.focused});

  final bool focused;
}

/// The window closed and its Flutter view [viewId] is gone. The app keeps
/// running in the menubar.
final class MenubarWindowClosed extends MenubarWindowEvent {
  const MenubarWindowClosed(this.viewId);

  final int viewId;
}
