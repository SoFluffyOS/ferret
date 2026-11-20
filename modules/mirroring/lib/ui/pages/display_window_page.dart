import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Another computer's extra display in a window of its own, full screen
/// from the start. Closing the window stops being that computer's
/// display; when it ends, the window leaves full screen to say how.
class DisplayWindowPage extends StatefulWidget {
  const DisplayWindowPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.onClose,
  });

  final String deviceId;
  final String deviceName;

  /// Closes the window.
  final VoidCallback onClose;

  @override
  State<DisplayWindowPage> createState() => _DisplayWindowPageState();
}

class _DisplayWindowPageState extends State<DisplayWindowPage> {
  late final ViewerViewModel _viewModel;
  late final StageWindowViewModel _window;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ViewerViewModel>()..openStage(widget.deviceId);
    _window = context.read<StageWindowViewModel>();
    _viewModel.addListener(_onViewer);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewer);
    unawaited(_viewModel.leaveStage(widget.deviceId));
    super.dispose();
  }

  void _onViewer() {
    final ended = _viewModel.sessionFor(widget.deviceId)?.phase == .ended;
    if (ended && _window.isFullScreen) {
      unawaited(_window.setFullScreen(false));
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: DisplayStageFrame(
      deviceId: widget.deviceId,
      deviceName: widget.deviceName,
      onClose: widget.onClose,
      onToggleFullScreen: () => unawaited(_window.toggleFullScreen()),
      onExitFullScreen: () => unawaited(_window.setFullScreen(false)),
    ),
  );
}
