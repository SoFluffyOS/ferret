/// One thing on the mirror toolbar.
enum ToolbarItem {
  back,
  home,
  recents,
  rotate,

  /// Saves the picture as it is now to a file.
  screenshot,
  keyboard,

  /// Takes the place of every control on a device that is view only.
  viewOnly,

  /// Takes the place of [viewOnly] on a device whose owner can let this
  /// computer control it: asks them.
  askControl,
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
    ToolbarItem.screenshot,
    ToolbarItem.keyboard,
    ToolbarItem.fullScreen,
  };

  static const _alwaysShown = {
    ToolbarItem.back,
    ToolbarItem.home,
    ToolbarItem.recents,
    ToolbarItem.viewOnly,
    ToolbarItem.askControl,
    ToolbarItem.more,
    ToolbarItem.stop,
  };

  /// What goes behind More one at a time, first to last, when a toolbar
  /// that is wide enough still has more than fits: names in a long
  /// language, or large text.
  static const _foldOrder = <ToolbarItem>[
    .screenshot,
    .keyboard,
    .rotate,
    .fullScreen,
    .quality,
  ];

  /// Folds [items] for a toolbar [width] wide. It goes by the toolbar's
  /// own room, not the window's: the same toolbar sits in a phone-shaped
  /// window, a pane and a page. [measure] says how wide a toolbar with
  /// these items really is; with it, a toolbar never shows more than fits.
  factory ToolbarFold.of(
    List<ToolbarItem> items,
    double width, {
    double Function(List<ToolbarItem> shown)? measure,
  }) {
    final byWidth = switch (width) {
      < tightBelow => {
        for (final item in items)
          if (!_alwaysShown.contains(item)) item,
      },
      < foldBelow => _firstToFold,
      _ => const <ToolbarItem>{},
    };
    final folded = {...byWidth};
    for (final next in _foldOrder) {
      final shown = [
        for (final item in items)
          if (!folded.contains(item)) item,
      ];
      if (measure == null || measure(shown) <= width) {
        break;
      }

      folded.add(next);
    }

    return ToolbarFold(
      shown: [
        for (final item in items)
          if (!folded.contains(item)) item,
      ],
      folded: [
        for (final item in items)
          if (folded.contains(item)) item,
      ],
    );
  }

  /// The slim bar of the picture's own window: the device's own keys, the
  /// view-only chip, More and Stop. The quality mark joins them while the
  /// picture is not good, so it is seen; the rest waits behind More.
  factory ToolbarFold.forBar(
    List<ToolbarItem> items, {
    bool showsQuality = false,
  }) {
    bool stays(ToolbarItem item) =>
        _alwaysShown.contains(item) || (showsQuality && item == .quality);

    return ToolbarFold(
      shown: [
        for (final item in items)
          if (stays(item)) item,
      ],
      folded: [
        for (final item in items)
          if (!stays(item)) item,
      ],
    );
  }

  final List<ToolbarItem> shown;
  final List<ToolbarItem> folded;
}
