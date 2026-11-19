import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The mirror stage in a window of its own: a slim bar on top, beside the
/// title bar's buttons, and the picture filling the rest in its own shape.
/// Closing the window stops sharing, like leaving the stage anywhere else.
class MirrorWindowPage extends StatefulWidget {
  const MirrorWindowPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.onClose,
    this.clock,
  });

  final String deviceId;
  final String deviceName;

  /// Closes the window.
  final VoidCallback onClose;
  final DateTime Function()? clock;

  @override
  State<MirrorWindowPage> createState() => _MirrorWindowPageState();
}

class _MirrorWindowPageState extends State<MirrorWindowPage> {
  late final ViewerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ViewerViewModel>()..openStage(widget.deviceId);
  }

  @override
  void dispose() {
    unawaited(_viewModel.leaveStage(widget.deviceId));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.background,
      child: MirrorStageFrame(
        deviceId: widget.deviceId,
        deviceName: widget.deviceName,
        onClose: widget.onClose,
        clock: widget.clock,
        fillsWindow: true,
        onDragWindow: () =>
            unawaited(context.read<StageWindowViewModel>().startDrag()),
      ),
    );
  }
}
