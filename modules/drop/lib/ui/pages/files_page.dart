import 'package:drop/l10n/l10n.dart';
import 'package:drop/ui/frames/frames.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Files with one device: where to drop or choose them, then what was sent
/// and received, with each transfer's progress and what to do with it.
class FilesPage extends StatelessWidget {
  const FilesPage({
    super.key,
    required this.viewModel,
    required this.deviceId,
    required this.deviceName,
    required this.isConnected,
  });

  final DropViewModel viewModel;
  final String deviceId;
  final String deviceName;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.dropL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider.value(
          value: viewModel,
          child: DeviceFilesFrame(
            deviceId: deviceId,
            deviceName: deviceName,
            isConnected: isConnected,
          ),
        ),
      ],
    );
  }
}
