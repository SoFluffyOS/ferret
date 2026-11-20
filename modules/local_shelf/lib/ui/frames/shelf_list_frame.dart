import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/ui/widgets/widgets.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Everything on the shelf, newest first. Click to select (⌘ adds, ⇧
/// takes a range), drag to take the selection out, Space for a preview,
/// Delete to take it off. Hidden items say only that they are hidden.
class ShelfListFrame extends StatelessWidget {
  const ShelfListFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.select<ShelfViewModel, List<ShelfItem>>(
      (viewModel) => viewModel.items,
    );
    final selected = context.select<ShelfViewModel, Set<String>>(
      (viewModel) => viewModel.selected,
    );
    final isHidden = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.isHidden,
    );
    final viewModel = context.read<ShelfViewModel>();
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final noteStyle = typography.caption1.copyWith(color: palette.mutedText);
    if (isHidden) {
      return Row(
        children: [
          Icon(LucideIcons.lock, size: Spacing.d16, color: palette.mutedText),
          Spacing.h8,
          Expanded(child: Text(l10n.hiddenNote, style: typography.base2)),
        ],
      );
    }

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text(
            l10n.empty,
            style: typography.base2.copyWith(color: palette.text),
          ),
          Spacing.v8,
          Text(l10n.emptyNote, style: noteStyle),
        ],
      );
    }

    final thumb = Spacing.d32;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            unawaited(viewModel.previewSelected()),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            viewModel.selectAll,
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            unawaited(viewModel.removeSelected()),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            unawaited(viewModel.removeSelected()),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            GroupedCard(
              separatorIndent: PageInsets.row + thumb + Spacing.d12,
              children: [
                for (final item in items)
                  _row(
                    context,
                    l10n,
                    viewModel,
                    item,
                    thumb: thumb,
                    isSelected: selected.contains(item.id),
                  ),
              ],
            ),
            Spacing.v8,
            Text(
              switch (selected.length) {
                0 || 1 => l10n.dragNote,
                final count => l10n.selectedCount(count),
              },
              style: noteStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    ShelfLocalizations l10n,
    ShelfViewModel viewModel,
    ShelfItem item, {
    required double thumb,
    required bool isSelected,
  }) {
    final palette = context.palette;
    final isHidden = viewModel.hides(item);
    final viewId = View.of(context).viewId;
    final name = switch (isHidden) {
      true => l10n.hiddenItem,
      false => ShelfLabels.nameOf(l10n, item),
    };

    return GestureDetector(
      key: ValueKey(item.id),
      onPanStart: (_) =>
          unawaited(viewModel.drag(viewId, viewModel.dragged(item))),
      child: GroupedRow(
        title: name,
        titleMaxLines: 1,
        subtitle: _subtitle(l10n, viewModel, item),
        isSelected: isSelected,
        leading: ShelfThumb(
          item: item,
          size: thumb,
          radius: Corners.tile,
          isHidden: isHidden,
        ),
        trailing: Tappable(
          tooltip: l10n.removeTooltip(name),
          semanticLabel: l10n.remove,
          semanticButton: true,
          onTap: () => unawaited(viewModel.remove([item.id])),
          child: Padding(
            padding: EdgeInsets.all(Spacing.d6),
            child: Icon(
              LucideIcons.x,
              size: Spacing.d16,
              color: palette.mutedText,
            ),
          ),
        ),
        onTap: () {
          final keyboard = HardwareKeyboard.instance;
          viewModel.select(
            item.id,
            toggle: keyboard.isMetaPressed || keyboard.isControlPressed,
            extend: keyboard.isShiftPressed,
          );
        },
      ),
    );
  }

  String _subtitle(
    ShelfLocalizations l10n,
    ShelfViewModel viewModel,
    ShelfItem item,
  ) {
    if (item.isMissing) {
      return l10n.missing;
    }

    final kind = ShelfLabels.kindOf(l10n, item.kind);
    final source = switch ((item.fromDeviceId, item.source)) {
      (final deviceId?, _) => l10n.fromDevice(viewModel.nameOf(deviceId)),
      (null, .dropped) => l10n.droppedHere,
      (null, .copied) => l10n.copiedHere,
    };

    return '$kind · $source';
  }
}
