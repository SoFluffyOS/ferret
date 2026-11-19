import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/mirroring_labels.dart';
import 'package:mirroring/ui/widgets/popup_row.dart';
import 'package:mirroring/ui/widgets/quality_mark.dart';
import 'package:mirroring/ui/widgets/toolbar_button.dart';
import 'package:mirroring/ui/widgets/toolbar_popup.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The mirror's one toolbar: the device's own keys, what this computer
/// adds, the quality mark, and Stop set apart at the end. It always sits
/// next to the picture, never on it: icons with tooltips in a pill under
/// the picture, folding what is used least behind More as it gets narrow;
/// icons with their names beside the picture; and only the essentials,
/// flat, in the top bar of the picture's own window.
class MirrorToolbar extends StatefulWidget {
  const MirrorToolbar({
    super.key,
    required this.items,
    required this.place,
    required this.onItem,
    required this.onButton,
    required this.qualityPanel,
    required this.viewOnlyPanel,
    this.soundPanel,
    this.soundDetail,
    this.soundMuted = false,
    this.quality = .good,
    this.moreButtons = const [],
    this.isFullScreen = false,
    this.pinned,
    this.onPinned,
    this.onPopup,
  });

  /// Everything the toolbar has for this device, in order. What doesn't
  /// fit goes behind More.
  final List<ToolbarItem> items;
  final ToolbarPlace place;

  /// A button that acts at once. Quality, More and the view-only chip
  /// open their own popups instead.
  final ValueChanged<ToolbarItem> onItem;

  /// One of [moreButtons], from behind More.
  final ValueChanged<DeviceButton> onButton;
  final WidgetBuilder qualityPanel;
  final WidgetBuilder viewOnlyPanel;

  /// Where the device's sound plays and how loud, behind More. Null on a
  /// computer that can't play it.
  final WidgetBuilder? soundPanel;

  /// Where the sound is right now, next to Sound in More.
  final String? soundDetail;

  /// No sound of the device plays here right now.
  final bool soundMuted;
  final ViewQuality quality;

  /// The device's keys that sit behind More: volume, power, its
  /// notifications panel.
  final List<DeviceButton> moreButtons;
  final bool isFullScreen;

  /// Whether the toolbar stays visible in the window's bar. Null where it
  /// never fades, so there is nothing to choose.
  final bool? pinned;
  final ValueChanged<bool>? onPinned;

  /// A popup opened or closed, for chrome that hides when idle.
  final ValueChanged<bool>? onPopup;

  @override
  State<MirrorToolbar> createState() => _MirrorToolbarState();
}

class _MirrorToolbarState extends State<MirrorToolbar> {
  final OverlayPortalController _more = OverlayPortalController();
  final OverlayPortalController _quality = OverlayPortalController();
  final OverlayPortalController _viewOnly = OverlayPortalController();

  /// What More shows in place of its list.
  _MorePage _morePage = .list;

  String get _modifier => switch (defaultTargetPlatform) {
    .macOS || .iOS => '⌘',
    _ => 'Ctrl+',
  };

  void _open(OverlayPortalController popup) {
    setState(() => _morePage = .list);
    popup.show();
    widget.onPopup?.call(true);
  }

  void _closeAll() {
    for (final popup in [_more, _quality, _viewOnly]) {
      if (popup.isShowing) {
        popup.hide();
      }
    }

    widget.onPopup?.call(false);
  }

  void _act(ToolbarItem item) {
    _closeAll();
    widget.onItem(item);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.place == .beside) {
      return _column(context);
    }

    if (widget.place == .bar) {
      return LayoutBuilder(
        builder: (context, constraints) =>
            _fittingBar(context, constraints.maxWidth),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fold = ToolbarFold.of(
          widget.items,
          constraints.maxWidth,
          measure: (shown) => _widthOf(context, shown),
        );
        final names = _widthOf(context, fold.shown) <= constraints.maxWidth;

        return _pill(context, fold, names: names);
      },
    );
  }

  /// How wide the pill is with [shown] in it: its buttons, the names two
  /// of them carry unless [names] is off, and the lines between its
  /// groups. The bar has no padding of its own, and Stop has no name
  /// there.
  double _widthOf(
    BuildContext context,
    List<ToolbarItem> shown, {
    bool names = true,
  }) {
    final l10n = context.mirroringL10n;
    final style = context.fluffyTheme.typography.base2;
    final scaler = MediaQuery.textScalerOf(context);
    double named(String name) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return Spacing.d28 + Spacing.d4 + width + Spacing.d8;
    }

    final inBar = widget.place == .bar;
    var width = switch (inBar) {
      true => 0.0,
      false => Spacing.d6 * 2,
    };
    for (final (index, item) in shown.indexed) {
      if (index > 0 && item.startsGroup) {
        width += Spacing.d4 * 2 + Spacing.d1;
      }

      width += switch (item) {
        .viewOnly when names => named(l10n.viewOnly),
        .stop when names && !inBar => named(l10n.stop),
        _ => Spacing.d28,
      };
    }

    return width;
  }

  /// The pill under the picture. Where even the folded pill is too wide,
  /// the view-only chip and Stop drop their names.
  Widget _pill(BuildContext context, ToolbarFold fold, {required bool names}) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const StadiumBorder(),
        shadows: [
          BoxShadow(
            color: palette.text.withValues(alpha: 0.18),
            blurRadius: Spacing.d16,
            offset: Offset(0, Spacing.d4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.d6),
        child: SizedBox(
          height: Spacing.d40,
          child: Row(
            mainAxisSize: .min,
            children: [
              for (final (index, item) in fold.shown.indexed) ...[
                if (index > 0 && item.startsGroup) _divider(context),
                _item(context, item, fold, names: names),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The most the window's bar can hold in [width]: the quality mark
  /// while the picture is not good, then the view-only chip's name, then
  /// just the essential icons.
  Widget _fittingBar(BuildContext context, double width) {
    final withQuality = ToolbarFold.forBar(
      widget.items,
      showsQuality: widget.quality != .good,
    );
    final plain = ToolbarFold.forBar(widget.items);
    for (final (fold, names) in [
      (withQuality, true),
      (plain, true),
    ]) {
      if (_widthOf(context, fold.shown, names: names) <= width) {
        return _bar(context, fold, names: names);
      }
    }

    return _bar(context, plain, names: false);
  }

  /// Flat icons in the window's bar, the same height as its title bar
  /// buttons.
  Widget _bar(
    BuildContext context,
    ToolbarFold fold, {
    required bool names,
  }) => Row(
    mainAxisSize: .min,
    children: [
      for (final (index, item) in fold.shown.indexed) ...[
        if (index > 0 && item.startsGroup) _divider(context),
        _item(context, item, fold, names: names),
      ],
    ],
  );

  Widget _column(BuildContext context) {
    final fold = ToolbarFold(shown: widget.items, folded: const []);

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          for (final (index, item) in fold.shown.indexed) ...[
            if (index > 0 && item.startsGroup) _divider(context),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _item(context, item, fold, showName: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final line = ColoredBox(
      color: context.palette.mutedText.withValues(alpha: 0.25),
      child: switch (widget.place.axis) {
        .horizontal => SizedBox(width: Spacing.d1, height: Spacing.d20),
        .vertical => SizedBox(height: Spacing.d1),
      },
    );

    return Padding(
      padding: switch (widget.place.axis) {
        .horizontal => EdgeInsets.symmetric(horizontal: Spacing.d4),
        .vertical => EdgeInsets.symmetric(vertical: Spacing.d6),
      },
      child: line,
    );
  }

  Widget _item(
    BuildContext context,
    ToolbarItem item,
    ToolbarFold fold, {
    bool showName = false,
    bool names = true,
  }) {
    final l10n = context.mirroringL10n;

    return switch (item) {
      .viewOnly => ToolbarPopup(
        controller: _viewOnly,
        place: widget.place,
        onClosed: () => widget.onPopup?.call(false),
        builder: widget.viewOnlyPanel,
        child: ToolbarButton(
          icon: LucideIcons.eye,
          name: l10n.viewOnly,
          showName: names,
          tone: .muted,
          onTap: () => _open(_viewOnly),
        ),
      ),
      .quality => ToolbarPopup(
        controller: _quality,
        place: widget.place,
        onClosed: () => widget.onPopup?.call(false),
        builder: widget.qualityPanel,
        child: ToolbarButton(
          icon: LucideIcons.signal,
          name: l10n.qualityName(widget.quality),
          tooltip: l10n.pictureTooltip(l10n.qualityName(widget.quality)),
          showName: showName,
          onTap: () => _open(_quality),
          child: QualityMark(quality: widget.quality),
        ),
      ),
      .more => ToolbarPopup(
        controller: _more,
        place: widget.place,
        onClosed: () => widget.onPopup?.call(false),
        builder: (context) => _moreMenu(context, fold),
        child: ToolbarButton(
          icon: LucideIcons.ellipsis,
          name: l10n.more,
          showName: showName,
          onTap: () => _open(_more),
        ),
      ),
      .stop => ToolbarButton(
        icon: LucideIcons.circleStop,
        name: l10n.stop,
        showName: names && widget.place != .bar,
        tone: .danger,
        onTap: () => _act(.stop),
      ),
      _ => ToolbarButton(
        icon: _iconOf(item),
        name: _nameOf(l10n, item),
        tooltip: _tooltipOf(l10n, item),
        showName: showName,
        onTap: () => _act(item),
      ),
    };
  }

  Widget _moreMenu(BuildContext context, ToolbarFold fold) {
    final l10n = context.mirroringL10n;
    final soundPanel = widget.soundPanel;
    if (_morePage == .quality) {
      return widget.qualityPanel(context);
    }

    if (_morePage == .sound && soundPanel != null) {
      return soundPanel(context);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            for (final item in fold.folded)
              switch (item) {
                .quality => PopupRow(
                  icon: LucideIcons.signal,
                  label: l10n.pictureTitle,
                  detail: l10n.qualityName(widget.quality),
                  onTap: () => setState(() => _morePage = .quality),
                ),
                _ => PopupRow(
                  icon: _iconOf(item),
                  label: _nameOf(l10n, item),
                  onTap: () => _act(item),
                ),
              },
            if (soundPanel != null)
              PopupRow(
                icon: switch (widget.soundMuted) {
                  true => LucideIcons.volumeX,
                  false => LucideIcons.volume2,
                },
                label: l10n.soundTitle,
                detail: widget.soundDetail,
                onTap: () => setState(() => _morePage = .sound),
              ),
            if (widget.pinned case final pinned?)
              PopupRow(
                label: l10n.keepToolbar,
                checked: pinned,
                onTap: () {
                  _closeAll();
                  widget.onPinned?.call(!pinned);
                },
              ),
            for (final button in widget.moreButtons)
              PopupRow(
                icon: _buttonIcon(button),
                label: l10n.buttonName(button),
                onTap: () {
                  _closeAll();
                  widget.onButton(button);
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconOf(ToolbarItem item) => switch (item) {
    .back => LucideIcons.chevronLeft,
    .home => LucideIcons.circle,
    .recents => LucideIcons.square,
    .rotate => LucideIcons.rotateCw,
    .screenshot => LucideIcons.camera,
    .keyboard => LucideIcons.keyboard,
    .fullScreen => switch (widget.isFullScreen) {
      true => LucideIcons.minimize,
      false => LucideIcons.maximize,
    },
    .viewOnly => LucideIcons.eye,
    .quality => LucideIcons.signal,
    .more => LucideIcons.ellipsis,
    .stop => LucideIcons.circleStop,
  };

  IconData _buttonIcon(DeviceButton button) => switch (button) {
    .notifications => LucideIcons.bell,
    .volumeUp => LucideIcons.volume2,
    .volumeDown => LucideIcons.volume1,
    .power => LucideIcons.power,
    .rotate => LucideIcons.rotateCw,
    .back => LucideIcons.chevronLeft,
    .home => LucideIcons.circle,
    .recents => LucideIcons.square,
  };

  String _nameOf(MirroringLocalizations l10n, ToolbarItem item) =>
      switch (item) {
        .back => l10n.buttonBack,
        .home => l10n.buttonHome,
        .recents => l10n.buttonRecents,
        .rotate => l10n.buttonRotate,
        .screenshot => l10n.buttonScreenshot,
        .keyboard => l10n.buttonKeyboard,
        .fullScreen => switch (widget.isFullScreen) {
          true => l10n.exitFullScreen,
          false => l10n.fullScreen,
        },
        .viewOnly => l10n.viewOnly,
        .quality => l10n.pictureTitle,
        .more => l10n.more,
        .stop => l10n.stop,
      };

  /// The name with the click or the keys that do the same.
  String _tooltipOf(MirroringLocalizations l10n, ToolbarItem item) {
    final name = _nameOf(l10n, item);
    final keys = switch (item) {
      .back => '${l10n.keyRightClick}, $_modifier[',
      .home => '${l10n.keyMiddleClick}, ${_modifier}1',
      .recents => '${_modifier}2',
      .rotate => '${_modifier}R',
      .screenshot => switch (defaultTargetPlatform) {
        .macOS || .iOS => '⇧⌘S',
        _ => 'Ctrl+Shift+S',
      },
      .keyboard => '${_modifier}K',
      _ => null,
    };
    if (keys == null) {
      return name;
    }

    return l10n.tooltipWithKey(name, keys);
  }
}

enum _MorePage { list, quality, sound }
