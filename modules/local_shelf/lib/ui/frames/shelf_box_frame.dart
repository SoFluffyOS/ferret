import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/ui/widgets/widgets.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf as an open box along the bottom of the popover, on every
/// page: what it holds shows as tiles, newest first. Drag a tile out to
/// take it, the stack at the start to take everything, or a selection
/// (⌘- or ⇧-click) to take that. Drop anything on the box to keep it.
/// Under the pointer a tile shows ⓧ to take it off; right-click for
/// Quick Look, Show in Finder, Copy and Remove. From the keyboard the
/// row is one Tab stop: the arrow keys move the selection (⇧ adds to it),
/// Space or Return previews it, and Delete takes it off. While previews are hidden here it shows only how many
/// things it holds.
class ShelfBoxFrame extends StatefulWidget {
  const ShelfBoxFrame({
    super.key,
    required this.onOpenList,
    this.padding,
    this.expands = false,
  });

  /// Opens the shelf as a list, with Keep copies.
  final VoidCallback onOpenList;

  /// Around the box; the page's side inset when null, with a little room
  /// below.
  final EdgeInsetsGeometry? padding;

  /// The box takes all the height it is given, such as in the floating
  /// panel, with what it holds centred.
  final bool expands;

  /// From this many items on, Clear asks once more.
  static const confirmsFrom = 6;

  /// How far the tiles sit inside the box. The box's corner is
  /// concentric with theirs.
  static double get inset => Spacing.d8;
  static double get radius => Corners.around(ShelfTile.radius, inset);

  /// The empty and the hidden box: one short line.
  static double get compactHeight => Spacing.d56;

  @override
  State<ShelfBoxFrame> createState() => _ShelfBoxFrameState();
}

class _ShelfBoxFrameState extends State<ShelfBoxFrame>
    with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode(debugLabel: 'shelf box');
  final Map<String, GlobalKey> _tileKeys = {};
  Set<String>? _seen;
  bool _confirmsClear = false;

  /// The tile the arrow keys move from: the last one clicked or reached.
  String? _cursor;

  /// The box took focus from a click, not from the keyboard: no ring
  /// until a key is pressed.
  bool _byPointer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus.addListener(_focusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.removeListener(_focusChanged);
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (!_focus.hasFocus) {
      _byPointer = false;
    }

    setState(() {});
  }

  /// The arrow keys move the selection along the row, ⇧ adds to it, and
  /// the tile they land on scrolls into view.
  void _step(ShelfViewModel viewModel, int by, {bool extend = false}) {
    final id = viewModel.selectNext(_cursor, by, extend: extend);
    if (id == null) {
      return;
    }

    setState(() => _cursor = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tile = _tileKeys[id]?.currentContext;
      if (tile == null || !tile.mounted) {
        return;
      }

      unawaited(
        Scrollable.ensureVisible(
          tile,
          duration: const Duration(milliseconds: 120),
          alignmentPolicy: switch (by < 0) {
            true => .keepVisibleAtStart,
            false => .keepVisibleAtEnd,
          },
        ),
      );
    });
  }

  /// The popover opening brings the app back: files may have moved since.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != .resumed) {
      return;
    }

    unawaited(context.read<ShelfViewModel>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final items = context.select<ShelfViewModel, List<ShelfItem>>(
      (viewModel) => viewModel.items,
    );
    final isDropOver = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.isDropOver,
    );
    final isHidden = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.isHidden,
    );
    final selected = context.select<ShelfViewModel, Set<String>>(
      (viewModel) => viewModel.selected,
    );
    final isListOpen = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.isListOpen,
    );
    final viewModel = context.read<ShelfViewModel>();
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final side = PageInsets.side(context.screenSize);
    if (isListOpen) {
      return const SizedBox.shrink();
    }

    final ids = {for (final item in items) item.id};
    _tileKeys.removeWhere((id, _) => !ids.contains(id));
    final seen = _seen ?? ids;
    final fresh = ids.difference(seen);
    _seen = ids;
    if (items.length < ShelfBoxFrame.confirmsFrom || isHidden) {
      _confirmsClear = false;
    }

    final content = switch ((items.isEmpty, isHidden)) {
      (true, _) => _line(
        context,
        icon: switch (isDropOver) {
          true => LucideIcons.arrowDownToLine,
          false => LucideIcons.inbox,
        },
        text: switch (isDropOver) {
          true => l10n.barDropOver,
          false => l10n.barEmpty,
        },
        isDropOver: isDropOver,
      ),
      (false, true) => _line(
        context,
        icon: LucideIcons.lock,
        text: l10n.barHidden(items.length),
        isDropOver: isDropOver,
      ),
      (false, false) => _tiles(
        context,
        viewModel,
        items,
        selected: selected,
        fresh: fresh,
        isDropOver: isDropOver,
      ),
    };
    final showsRing = _focus.hasFocus && !_byPointer;
    // The ring is drawn over the box, so the tiles never move for it.
    final ring = Corners.shape(
      ShelfBoxFrame.radius,
      side: BorderSide(
        color: palette.accent,
        width: Spacing.d2,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    );
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: BoxConstraints(minHeight: ShelfBoxFrame.compactHeight),
      alignment: switch (widget.expands) {
        true => Alignment.center,
        false => null,
      },
      decoration: ShapeDecoration(
        color: switch (isDropOver) {
          true => palette.accent.withValues(alpha: 0.12),
          false => palette.surface,
        },
        shape: Corners.shape(ShelfBoxFrame.radius),
      ),
      foregroundDecoration: switch (isDropOver || showsRing) {
        true => ShapeDecoration(shape: ring),
        false => null,
      },
      clipBehavior: .antiAlias,
      child: content,
    );

    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding:
            widget.padding ?? EdgeInsets.fromLTRB(side, 0, side, Spacing.d8),
        child: DropReceiverRegion(
          receiver: viewModel,
          child: Semantics(
            container: true,
            label: l10n.title,
            hint: l10n.barEmpty,
            child: Column(
              mainAxisSize: switch (widget.expands) {
                true => .max,
                false => .min,
              },
              crossAxisAlignment: .stretch,
              children: [
                _header(context, viewModel, items, selected, isHidden),
                _fill(switch (items.isEmpty && !isDropOver) {
                  true => DashedOutline(
                    radius: ShelfBoxFrame.radius,
                    color: palette.mutedText.withValues(alpha: 0.45),
                    child: box,
                  ),
                  false => box,
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fill(Widget box) => switch (widget.expands) {
    true => Expanded(child: box),
    false => box,
  };

  /// "Shelf · 5 items", with Clear and the list at the end.
  Widget _header(
    BuildContext context,
    ShelfViewModel viewModel,
    List<ShelfItem> items,
    Set<String> selected,
    bool isHidden,
  ) {
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final titleStyle = typography.caption1.copyWith(
      color: palette.mutedText,
      fontWeight: .w600,
    );
    final countStyle = typography.caption1.copyWith(color: palette.mutedText);
    final count = items.length;
    final canClear = count > 0 && !isHidden;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: PageInsets.row,
        end: Spacing.d2,
        bottom: Spacing.d2,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: TextLink.minHeight),
        child: Row(
          children: [
            Text(l10n.title, style: titleStyle),
            Spacing.h6,
            Expanded(
              child: switch (count > 0 && !isHidden) {
                true => Text(
                  switch (selected.length) {
                    0 || 1 => l10n.barCount(count),
                    final picked => l10n.selectedCount(picked),
                  },
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: countStyle,
                ),
                false => const SizedBox.shrink(),
              },
            ),
            if (canClear && _confirmsClear) ...[
              TextLink(
                label: l10n.cancel,
                onTap: () => setState(() => _confirmsClear = false),
              ),
              _DangerLink(
                label: l10n.clearConfirm(count),
                tooltip: l10n.clearConfirmTooltip(count),
                onTap: () {
                  setState(() => _confirmsClear = false);
                  unawaited(viewModel.clear());
                },
              ),
            ],
            if (canClear && !_confirmsClear)
              FluffyTooltip(
                message: l10n.clearTooltip,
                child: TextLink(
                  label: l10n.clear,
                  onTap: () {
                    if (count < ShelfBoxFrame.confirmsFrom) {
                      unawaited(viewModel.clear());
                      return;
                    }

                    setState(() => _confirmsClear = true);
                  },
                ),
              ),
            Spacing.h4,
            Tappable(
              tooltip: l10n.barOpen,
              semanticLabel: l10n.barOpen,
              semanticButton: true,
              onTap: widget.onOpenList,
              child: SizedBox.square(
                dimension: TextLink.minHeight,
                child: Icon(
                  LucideIcons.list,
                  size: Spacing.d16,
                  color: palette.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isDropOver,
  }) {
    final palette = context.palette;
    final color = switch (isDropOver) {
      true => palette.link,
      false => palette.mutedText,
    };
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: color,
      fontWeight: switch (isDropOver) {
        true => .w600,
        false => null,
      },
    );

    return SizedBox(
      height: ShelfBoxFrame.compactHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.d16),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Icon(icon, size: Spacing.d16, color: color),
            Spacing.h8,
            Flexible(
              child: Text(text, maxLines: 2, overflow: .ellipsis, style: style),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tiles(
    BuildContext context,
    ShelfViewModel viewModel,
    List<ShelfItem> items, {
    required Set<String> selected,
    required Set<String> fresh,
    required bool isDropOver,
  }) {
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final viewId = View.of(context).viewId;
    final gap = Spacing.d4;
    final row = Listener(
      onPointerSignal: _scrollSideways,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: .horizontal,
        padding: EdgeInsets.all(ShelfBoxFrame.inset),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            ShelfTile(
              key: const ValueKey('shelf-all'),
              thumb: _StackThumb(count: items.length),
              label: l10n.allTile(items.length),
              tooltip: l10n.dragAll(items.length),
              labelStyle: TextStyle(color: palette.link, fontWeight: .w600),
              onTap: () {
                _byPointer = true;
                _focus.requestFocus();
                viewModel.selectAll();
              },
              onDragStart: () => unawaited(viewModel.drag(viewId, items)),
            ),
            for (final item in items) ...[
              SizedBox(width: gap),
              _tile(
                context,
                viewModel,
                item,
                viewId: viewId,
                isSelected: selected.contains(item.id),
                isFresh: fresh.contains(item.id),
              ),
            ],
          ],
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            unawaited(viewModel.previewSelected()),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            unawaited(viewModel.previewSelected()),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _step(viewModel, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _step(viewModel, -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () =>
            _step(viewModel, 1, extend: true),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () =>
            _step(viewModel, -1, extend: true),
        const SingleActivator(LogicalKeyboardKey.home): () =>
            _step(viewModel, -items.length),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            _step(viewModel, items.length),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            viewModel.selectAll,
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            unawaited(viewModel.removeSelected()),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            unawaited(viewModel.removeSelected()),
      },
      child: Focus(
        focusNode: _focus,
        onKeyEvent: (_, _) {
          if (_byPointer) {
            setState(() => _byPointer = false);
          }

          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: .translucent,
          onTap: viewModel.clearSelection,
          child: Stack(
            alignment: .center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: switch (isDropOver) {
                  true => 0.3,
                  false => 1,
                },
                child: row,
              ),
              if (isDropOver)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.background,
                      shape: Corners.shape(Corners.capsule),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Spacing.d12,
                        vertical: Spacing.d6,
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Icon(
                            LucideIcons.arrowDownToLine,
                            size: Spacing.d16,
                            color: palette.link,
                          ),
                          Spacing.h8,
                          Text(
                            l10n.barDropOver,
                            style: context.fluffyTheme.typography.caption1
                                .copyWith(
                                  color: palette.link,
                                  fontWeight: .w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    ShelfViewModel viewModel,
    ShelfItem item, {
    required int viewId,
    required bool isSelected,
    required bool isFresh,
  }) {
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final isHidden = viewModel.hides(item);
    final name = switch (isHidden) {
      true => l10n.hiddenItem,
      false => _shownName(l10n, item),
    };
    final dragged = viewModel.dragged(item);
    final removeLabel = l10n.removeTooltip(name);

    return ContextMenuRegion(
      key: _tileKeys.putIfAbsent(item.id, GlobalKey.new),
      entries: [
        if (!isHidden && !item.isMissing)
          MenuEntry(
            label: l10n.quickLook,
            icon: LucideIcons.eye,
            onSelected: () => unawaited(viewModel.preview(dragged)),
          ),
        if (viewModel.canReveal(item))
          MenuEntry(
            label: l10n.showInFinder,
            icon: LucideIcons.folderSearch,
            onSelected: () => unawaited(viewModel.showInFinder(item)),
          ),
        if (viewModel.canCopy(item))
          MenuEntry(
            label: l10n.copy,
            icon: LucideIcons.copy,
            onSelected: () => unawaited(viewModel.copy(item)),
          ),
        MenuEntry(
          label: l10n.remove,
          icon: LucideIcons.x,
          startsGroup: !isHidden,
          onSelected: () => unawaited(
            viewModel.remove([for (final each in dragged) each.id]),
          ),
        ),
      ],
      child: ShelfTile(
        thumb: Opacity(
          opacity: switch (item.isMissing) {
            true => 0.5,
            false => 1,
          },
          child: ShelfThumb(
            item: item,
            size: ShelfTile.thumbSize,
            radius: ShelfTile.thumbRadius,
            isHidden: isHidden,
          ),
        ),
        label: name,
        tooltip: switch (item.isMissing) {
          true => '$name · ${l10n.missing}',
          false => name,
        },
        labelStyle: switch (item.isMissing || isHidden) {
          true => TextStyle(color: palette.mutedText),
          false => null,
        },
        middleEllipsis: item.kind != .text,
        isSelected: isSelected,
        isFresh: isFresh,
        onTap: () {
          _byPointer = true;
          _cursor = item.id;
          _focus.requestFocus();
          final keyboard = HardwareKeyboard.instance;
          viewModel.select(
            item.id,
            toggle: keyboard.isMetaPressed || keyboard.isControlPressed,
            extend: keyboard.isShiftPressed,
          );
        },
        onDragStart: () =>
            unawaited(viewModel.drag(viewId, viewModel.dragged(item))),
        onRemove: () => unawaited(viewModel.remove([item.id])),
        removeTooltip: removeLabel,
        removeLabel: l10n.remove,
      ),
    );
  }

  /// A link without its "https://", so the site shows first.
  String _shownName(ShelfLocalizations l10n, ShelfItem item) {
    final name = ShelfLabels.nameOf(l10n, item);
    if (item.kind != .link) {
      return name;
    }

    return name.replaceFirst(RegExp('^https?://(www\\.)?'), '');
  }

  /// A mouse wheel turns sideways in the box, so a mouse without a
  /// sideways wheel still reaches the oldest tiles.
  void _scrollSideways(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scroll.hasClients) {
      return;
    }

    final delta = event.scrollDelta;
    if (delta.dy == 0 || delta.dx != 0) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final position = _scroll.position;
      _scroll.jumpTo(
        (position.pixels + delta.dy).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }
}

/// The stack at the start of the box: drag it to take everything.
class _StackThumb extends StatelessWidget {
  const _StackThumb({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.accent,
        shape: Corners.shape(ShelfTile.thumbRadius),
      ),
      child: Center(
        child: Icon(
          LucideIcons.layers,
          size: Spacing.d24,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// "Clear 6" in red: the second press that takes everything off.
class _DangerLink extends StatelessWidget {
  const _DangerLink({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tappable(
    tooltip: tooltip,
    semanticButton: true,
    onTap: onTap,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: TextLink.minHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.d4),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: context.palette.danger,
              fontWeight: .w600,
            ),
          ),
        ),
      ),
    ),
  );
}
