import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/ui/frames/frames.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf as a list, opened from its box: everything on it with where
/// it came from, to drag out, preview or take off, and Keep copies. Clear
/// asks once more when it would take many things.
class ShelfPage extends StatefulWidget {
  const ShelfPage({super.key, required this.viewModel});

  final ShelfViewModel viewModel;

  /// From this many items on, Clear asks once more.
  static const confirmsFrom = ShelfBoxFrame.confirmsFrom;

  @override
  State<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> {
  bool _confirmsClear = false;
  bool _isCounted = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.refresh());
    // Told after this frame: the box below is built in the same one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _isCounted = true;
      widget.viewModel.listOpened();
    });
  }

  @override
  void dispose() {
    if (_isCounted) {
      final viewModel = widget.viewModel;
      // Not while the tree is being torn down: the box rebuilds on it.
      scheduleMicrotask(viewModel.listClosed);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: widget.viewModel,
    child: DropReceiverRegion(
      receiver: widget.viewModel,
      child: Builder(builder: _page),
    ),
  );

  Widget _page(BuildContext context) {
    final items = context.select<ShelfViewModel, List<ShelfItem>>(
      (viewModel) => viewModel.items,
    );
    final isHidden = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.isHidden,
    );
    final l10n = context.shelfL10n;
    final count = items.length;
    final canClear = count > 0 && !isHidden;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      actions: [
        if (canClear && _confirmsClear) ...[
          GhostButton(
            mainAxisSize: .min,
            label: l10n.cancel,
            onPressed: () => setState(() => _confirmsClear = false),
          ),
          Spacing.h8,
          GhostButton(
            mainAxisSize: .min,
            color: context.palette.danger,
            label: l10n.clearConfirm(count),
            tooltip: l10n.clearConfirmTooltip(count),
            onPressed: _clear,
          ),
        ],
        if (canClear && !_confirmsClear)
          GhostButton(
            mainAxisSize: .min,
            label: l10n.clear,
            tooltip: l10n.clearTooltip,
            onPressed: () {
              if (count < ShelfPage.confirmsFrom) {
                _clear();
                return;
              }

              setState(() => _confirmsClear = true);
            },
          ),
      ],
      children: [
        const ShelfListFrame(),
        if (!isHidden) ...[Spacing.v24, const ShelfCopiesFrame()],
      ],
    );
  }

  void _clear() {
    setState(() => _confirmsClear = false);
    unawaited(widget.viewModel.clear());
  }
}
