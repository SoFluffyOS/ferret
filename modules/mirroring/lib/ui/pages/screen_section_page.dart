import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/ui/pages/mirror_page.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// A device's Screen section. Before anything is shown it is the
/// launcher. Once Show screen was pressed, the stage is in a window of its
/// own where there is one, and the section says where things stand;
/// elsewhere the section hosts the stage itself, from the first question
/// to the ending.
class ScreenSectionPage extends StatelessWidget {
  const ScreenSectionPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.onShow,
    this.clock,
  });

  final String deviceId;
  final String deviceName;

  /// Show screen was pressed on the launcher.
  final VoidCallback onShow;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final hasStage = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.stageDeviceId == deviceId,
    );
    final inWindow = context.select<StageWindowViewModel, bool>(
      (stageWindow) => stageWindow.deviceId == deviceId,
    );
    final background = context.palette.background;
    if (inWindow) {
      return ColoredBox(
        color: background,
        child: AdaptiveContent(
          width: .narrow,
          child: ScreenStatusFrame(deviceId: deviceId, deviceName: deviceName),
        ),
      );
    }

    if (hasStage) {
      return MirrorPage(
        deviceId: deviceId,
        deviceName: deviceName,
        clock: clock,
      );
    }

    return ColoredBox(
      color: background,
      child: AdaptiveContent(
        width: .narrow,
        child: ScreenLauncherFrame(deviceName: deviceName, onShow: onShow),
      ),
    );
  }
}
