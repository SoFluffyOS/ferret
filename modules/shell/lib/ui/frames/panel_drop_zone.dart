import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';

/// Drops on the floating panel: it has no device tiles, only what a
/// feature drew, so a drag goes to the feature's own place to drop under
/// the pointer, such as the shelf, or nowhere. Sits at its view's top
/// left, since drag positions are view coordinates.
class PanelDropZone extends StatefulWidget {
  const PanelDropZone({super.key, required this.menubar, required this.child});

  final FerretMenubar menubar;
  final Widget child;

  @override
  State<PanelDropZone> createState() => _PanelDropZoneState();
}

class _PanelDropZoneState extends State<PanelDropZone> {
  StreamSubscription<PopoverDrag>? _drags;
  int? _viewId;
  DropReceiver? _hovered;

  late final RenderTreeDropTargetFinder _finder = RenderTreeDropTargetFinder(
    viewId: () => _viewId,
  );

  @override
  void initState() {
    super.initState();
    _drags = widget.menubar.drags.listen(_onDrag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewId = View.of(context).viewId;
  }

  @override
  void dispose() {
    unawaited(_drags?.cancel());
    _hover(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _onDrag(PopoverDrag drag) {
    if (drag.viewId != _viewId) {
      return;
    }

    switch (drag) {
      case PopoverDragEntered(:final position):
        _locate(position);
      case PopoverDragMoved(:final position):
        _locate(position);
      case PopoverDragExited():
        _hover(null);
      case PopoverDragDropped(:final paths, :final position):
        final receiver = _locate(position);
        _hover(null);
        if (receiver != null && paths.isNotEmpty) {
          unawaited(receiver.takeFiles(paths));
        }
      case PopoverTextDropped(:final text, :final position, :final isLink):
        final receiver = _locate(position);
        _hover(null);
        if (receiver != null && text.trim().isNotEmpty) {
          unawaited(
            receiver.takeText(
              text,
              isLink: DropKind.ofText(text, isLink: isLink) == .link,
            ),
          );
        }
    }
  }

  DropReceiver? _locate(Offset position) {
    final receiver = switch (_finder.find(position)) {
      ReceiverDropTarget(:final receiver) => receiver,
      _ => null,
    };
    _hover(receiver);
    return receiver;
  }

  void _hover(DropReceiver? receiver) {
    if (identical(receiver, _hovered)) {
      return;
    }

    _hovered?.hover(over: false);
    _hovered = receiver;
    receiver?.hover(over: true);
    final viewId = _viewId;
    if (viewId != null) {
      unawaited(
        widget.menubar.setDropAllowed(viewId, allowed: receiver != null),
      );
    }
  }
}
