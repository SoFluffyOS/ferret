import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/ui/widgets/widgets.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf's bar along the bottom of the popover, on every page: drop
/// something on it to keep it, drag the stack to take everything out or
/// one picture to take that one, click it to open the shelf. While
/// previews are hidden here it shows only how many things it holds.
class ShelfBarFrame extends StatefulWidget {
  const ShelfBarFrame({super.key, required this.onOpen});

  final VoidCallback onOpen;

  /// The thumbnails' side, and the gap between them.
  static double get thumbSize => Spacing.d28;
  static double get thumbGap => Spacing.d4;

  /// How far the thumbnails sit inside the bar's corners.
  static double get inset => Spacing.d6;

  @override
  State<ShelfBarFrame> createState() => _ShelfBarFrameState();
}

class _ShelfBarFrameState extends State<ShelfBarFrame>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    final viewModel = context.read<ShelfViewModel>();
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final side = PageInsets.side(context.screenSize);
    final radius = Corners.control;
    final noteStyle = typography.caption1.copyWith(
      color: switch (isDropOver) {
        true => palette.accent,
        false => palette.mutedText,
      },
    );
    final content = switch ((items.isEmpty, isHidden)) {
      (true, _) => _line(
        icon: LucideIcons.inbox,
        text: switch (isDropOver) {
          true => l10n.barDropOver,
          false => l10n.barEmpty,
        },
        style: noteStyle,
      ),
      (false, true) => _line(
        icon: LucideIcons.lock,
        text: l10n.barHidden(items.length),
        style: noteStyle,
      ),
      (false, false) => _items(
        context,
        viewModel,
        items,
        radius: Corners.inner(radius, ShelfBarFrame.inset),
        label: switch (isDropOver) {
          true => l10n.barDropOver,
          false => l10n.barCount(items.length),
        },
        style: noteStyle,
      ),
    };

    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, Spacing.d4, side, Spacing.d8),
        child: DropReceiverRegion(
          receiver: viewModel,
          child: Semantics(
            container: true,
            label: l10n.title,
            child: Tappable(
              tooltip: l10n.barOpen,
              semanticButton: true,
              enableAnimation: false,
              onTap: widget.onOpen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                constraints: BoxConstraints(minHeight: Spacing.d40),
                padding: EdgeInsets.symmetric(
                  horizontal: ShelfBarFrame.inset,
                  vertical: ShelfBarFrame.inset,
                ),
                decoration: ShapeDecoration(
                  color: switch (isDropOver) {
                    true => palette.accent.withValues(alpha: 0.14),
                    false => palette.surface,
                  },
                  shape: Corners.shape(
                    radius,
                    side: switch (isDropOver) {
                      true => BorderSide(
                        color: palette.accent,
                        width: Spacing.d1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      false => BorderSide.none,
                    },
                  ),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line({
    required IconData icon,
    required String text,
    required TextStyle style,
  }) => Row(
    children: [
      SizedBox.square(
        dimension: ShelfBarFrame.thumbSize,
        child: Icon(icon, size: Spacing.d16, color: style.color),
      ),
      Spacing.h4,
      Expanded(
        child: Text(text, maxLines: 1, overflow: .ellipsis, style: style),
      ),
    ],
  );

  Widget _items(
    BuildContext context,
    ShelfViewModel viewModel,
    List<ShelfItem> items, {
    required double radius,
    required String label,
    required TextStyle style,
  }) {
    final l10n = context.shelfL10n;
    final size = ShelfBarFrame.thumbSize;
    final gap = ShelfBarFrame.thumbGap;
    final viewId = View.of(context).viewId;

    return Row(
      children: [
        Tappable(
          tooltip: l10n.dragAll(items.length),
          onTap: widget.onOpen,
          enableAnimation: false,
          child: GestureDetector(
            onPanStart: (_) => unawaited(viewModel.drag(viewId, items)),
            child: _StackTile(size: size, radius: radius),
          ),
        ),
        Spacing.h8,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fits = ((constraints.maxWidth + gap) / (size + gap))
                  .floor()
                  .clamp(0, items.length);

              return Row(
                children: [
                  for (final item in items.take(fits)) ...[
                    Tappable(
                      tooltip: switch (viewModel.hides(item)) {
                        true => l10n.hiddenItem,
                        false => ShelfLabels.nameOf(l10n, item),
                      },
                      onTap: widget.onOpen,
                      enableAnimation: false,
                      child: GestureDetector(
                        onPanStart: (_) =>
                            unawaited(viewModel.drag(viewId, [item])),
                        child: ShelfThumb(
                          item: item,
                          size: size,
                          radius: radius,
                          isHidden: viewModel.hides(item),
                        ),
                      ),
                    ),
                    if (item != items.take(fits).last) SizedBox(width: gap),
                  ],
                ],
              );
            },
          ),
        ),
        Spacing.h8,
        Text(label, maxLines: 1, style: style),
        Spacing.h4,
        Icon(LucideIcons.chevronUp, size: Spacing.d16, color: style.color),
        Spacing.h4,
      ],
    );
  }
}

/// The shelf's whole stack, to drag everything at once.
class _StackTile extends StatelessWidget {
  const _StackTile({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.accent,
          shape: Corners.shape(radius),
        ),
        child: Center(
          child: Icon(
            LucideIcons.layers,
            size: Spacing.d16,
            color: palette.background,
          ),
        ),
      ),
    );
  }
}
