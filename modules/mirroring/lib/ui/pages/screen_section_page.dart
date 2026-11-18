import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/ui/pages/mirror_page.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// A device's Screen section. Before anything is shown it is the
/// launcher; once Show screen was pressed it hosts the mirror stage, from
/// the first question to the ending.
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
    if (hasStage) {
      return MirrorPage(
        deviceId: deviceId,
        deviceName: deviceName,
        clock: clock,
      );
    }

    return ColoredBox(
      color: context.palette.background,
      child: AdaptiveContent(
        width: .narrow,
        child: ScreenLauncherFrame(deviceName: deviceName, onShow: onShow),
      ),
    );
  }
}
