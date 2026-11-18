import 'package:flutter/widgets.dart';
import 'package:notifications/ui/frames/app_picker_frame.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';

/// Picks the apps whose notifications mirror, on [deviceName].
class AppPickerPage extends StatelessWidget {
  const AppPickerPage({
    super.key,
    required this.deviceName,
    required this.load,
    required this.save,
  });

  final String deviceName;
  final Future<List<AppEntry>> Function() load;
  final Future<void> Function(String package, bool allowed) save;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AppPickerViewModel(load: load, save: save),
    child: AppPickerFrame(deviceName: deviceName),
  );
}
