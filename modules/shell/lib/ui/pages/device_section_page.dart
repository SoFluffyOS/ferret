import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/pages/device_page.dart';

/// One section of a device: its Overview, or the page a feature has for it.
/// A section that is gone (the feature stopped applying to the device)
/// falls back to the Overview, never to a blank page.
class DeviceSectionPage extends StatelessWidget {
  const DeviceSectionPage({
    super.key,
    required this.deviceId,
    required this.sectionId,
  });

  final String deviceId;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    if (sectionId == FeatureSection.overviewId) {
      return DevicePage(deviceId: deviceId);
    }

    final status = context.select<EngineHost, DeviceStatus?>(
      (host) => host.statusOf(deviceId),
    );
    if (status == null) {
      return DevicePage(deviceId: deviceId);
    }

    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final sections = DeviceSections.of(
          context,
          scope.features,
          scope.featureContext,
          status,
        );
        for (final section in sections) {
          if (section.id == sectionId) {
            return KeyedSubtree(
              key: ValueKey(section.id),
              child: section.builder(context),
            );
          }
        }

        return DevicePage(deviceId: deviceId);
      },
    );
  }
}
