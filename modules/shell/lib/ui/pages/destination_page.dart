import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/pages/activity_page.dart';
import 'package:shell/ui/pages/device_section_page.dart';
import 'package:shell/ui/pages/settings_page.dart';

/// The page behind a [WindowDestination]: the same one whether it is the
/// pane's first page in a window or pushed on a phone.
class DestinationPage extends StatelessWidget {
  const DestinationPage({super.key, required this.destination});

  final WindowDestination destination;

  @override
  Widget build(BuildContext context) => switch (destination) {
    DeviceDestination(:final deviceId, :final sectionId) => DeviceSectionPage(
      key: ValueKey(destination),
      deviceId: deviceId,
      sectionId: sectionId,
    ),
    ActivityDestination() => const ActivityPage(),
    SettingsDestination() => const SettingsPage(),
  };
}
