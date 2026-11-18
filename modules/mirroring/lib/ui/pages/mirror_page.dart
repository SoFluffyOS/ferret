import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Opened by "Show screen" on a phone: the phone's screen with its toolbar
/// and status line. Back leaves mirroring running (the home card has Open
/// and Stop); Stop ends it on both devices.
class MirrorPage extends StatefulWidget {
  const MirrorPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;

  @override
  State<MirrorPage> createState() => _MirrorPageState();
}

class _MirrorPageState extends State<MirrorPage> {
  late final ViewerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ViewerViewModel>();
    unawaited(_viewModel.refreshWindow());
  }

  @override
  void dispose() {
    unawaited(_viewModel.leavePage());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          MirrorToolbarFrame(deviceName: widget.deviceName),
          Expanded(
            child: MirrorViewFrame(
              deviceId: widget.deviceId,
              deviceName: widget.deviceName,
            ),
          ),
          const MirrorControlsFrame(),
          const MirrorStatusFrame(),
        ],
      ),
    ),
  );
}
