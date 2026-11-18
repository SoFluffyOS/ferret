/// One thing on the mirror toolbar.
enum ToolbarItem {
  back,
  home,
  recents,
  rotate,
  keyboard,

  /// Takes the place of every control on a device that is view only.
  viewOnly,
  quality,
  fullScreen,
  more,
  stop;

  /// Starts a new group on the toolbar, set apart from the one before.
  bool get startsGroup => switch (this) {
    .rotate || .quality || .stop => true,
    _ => false,
  };
}

/// Which items a toolbar shows for the room it has, and which wait
/// behind More.
class ToolbarFold {
  const ToolbarFold({required this.shown, required this.folded});

  /// Below this width, what is used least moves behind More.
  static const foldBelow = 360.0;

  /// Below this width, only the device's own keys, More and Stop stay.
  static const tightBelow = 280.0;

  static const _firstToFold = {
    ToolbarItem.rotate,
    ToolbarItem.keyboard,
    ToolbarItem.fullScreen,
  };

  static const _alwaysShown = {
    ToolbarItem.back,
    ToolbarItem.home,
    ToolbarItem.recents,
    ToolbarItem.viewOnly,
    ToolbarItem.more,
    ToolbarItem.stop,
  };

  /// Folds [items] for a toolbar [width] wide. It goes by the toolbar's
  /// own room, not the window's: the same toolbar sits in a phone-shaped
  /// window, a pane and a page.
  factory ToolbarFold.of(List<ToolbarItem> items, double width) {
    final folds = switch (width) {
      < tightBelow => (ToolbarItem item) => !_alwaysShown.contains(item),
      < foldBelow => _firstToFold.contains,
      _ => (ToolbarItem item) => false,
    };

    return ToolbarFold(
      shown: [
        for (final item in items)
          if (!folds(item)) item,
      ],
      folded: [
        for (final item in items)
          if (folds(item)) item,
      ],
    );
  }

  final List<ToolbarItem> shown;
  final List<ToolbarItem> folded;
}
