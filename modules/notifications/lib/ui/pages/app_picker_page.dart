import 'package:flutter/widgets.dart';
import 'package:notifications/ui/frames/frames.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';

/// Chooses which apps' notifications mirror from [deviceName].
class AppPickerPage extends StatelessWidget {
  const AppPickerPage({
    super.key,
    required this.deviceName,
    required this.load,
    required this.update,
  });

  final String deviceName;
  final Future<AppList> Function() load;
  final Future<MirrorSettings> Function(UpdateMirrorSettings update) update;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AppPickerViewModel(load: load, update: update),
    child: AppPickerFrame(deviceName: deviceName),
  );
}
