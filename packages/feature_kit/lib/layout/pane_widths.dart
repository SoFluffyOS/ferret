/// The fixed widths of a window's panes, and how wide its content may get,
/// in logical pixels.
abstract final class PaneWidths {
  /// The device list on a `normal` view, where the content needs the room.
  static const double narrowSidebar = 220;

  /// The device list from `large` up.
  static const double sidebar = 240;

  /// The Activity pane on the trailing side, from `larger` up.
  static const double activity = 320;

  /// The widest a list or a form gets. Past it, the margins grow.
  static const double content = 720;

  /// The widest pairing and empty states get.
  static const double narrowContent = 480;

  /// Under this height a view keeps the phone layout whatever its width: a
  /// phone on its side has no room for two panes.
  static const double minSplitHeight = 480;
}
