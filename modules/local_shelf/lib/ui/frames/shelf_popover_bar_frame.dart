import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The shelf under the popover's pages once there is a device to send to,
/// as soon as it holds something, and while something is dragged over the
/// popover. On the welcome, before anything is paired, an empty box only
/// takes room from the first steps. The panel that follows a drag shows
/// the shelf either way.
class ShelfPopoverBarFrame extends StatefulWidget {
  const ShelfPopoverBarFrame({
    super.key,
    required this.trustStore,
    required this.child,
  });

  final TrustStore trustStore;

  /// The shelf's box.
  final Widget child;

  @override
  State<ShelfPopoverBarFrame> createState() => _ShelfPopoverBarFrameState();
}

class _ShelfPopoverBarFrameState extends State<ShelfPopoverBarFrame> {
  late bool _hasDevices;
  StreamSubscription<List<Object?>>? _devices;

  @override
  void initState() {
    super.initState();
    _hasDevices = widget.trustStore.devices.isNotEmpty;
    _devices = widget.trustStore.changes.listen((devices) {
      if (devices.isNotEmpty != _hasDevices) {
        setState(() => _hasDevices = devices.isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_devices?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holdsSomething = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.items.isNotEmpty,
    );
    if (!_hasDevices &&
        !holdsSomething &&
        !DragOverScope.isDraggingIn(context)) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}
