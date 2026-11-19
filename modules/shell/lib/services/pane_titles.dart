import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/device_sections.dart';
import 'package:shell/services/engine_host.dart';
import 'package:shell/view_models/view_models.dart';

/// What a window's pane shows, in words: the place, and the device it
/// belongs to when it is one of a device's sections.
typedef PaneTitle = ({String place, String? deviceName, bool isOverview});

abstract final class PaneTitles {
  /// The title of what [context]'s window has selected. Rebuilds the
  /// caller when the selection, the device or its name changes.
  static PaneTitle of(BuildContext context) {
    final l10n = context.shellL10n;
    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => viewModel.selection,
    );
    final shownTitle = context.select<WindowNavViewModel, String?>(
      (viewModel) => viewModel.shownTitle,
    );
    if (shownTitle != null) {
      return (place: shownTitle, deviceName: null, isOverview: false);
    }

    final device = context.select<EngineHost, DeviceStatus?>(
      (host) => switch (selection) {
        DeviceDestination(:final deviceId) => host.statusOf(deviceId),
        _ => null,
      },
    );

    switch (selection) {
      case null:
        return (place: l10n.appName, deviceName: null, isOverview: false);
      case ActivityDestination():
        return (place: l10n.activityTitle, deviceName: null, isOverview: false);
      case SettingsDestination():
        return (place: l10n.settingsTitle, deviceName: null, isOverview: false);
      case DeviceDestination(:final sectionId):
        if (device == null) {
          return (place: l10n.appName, deviceName: null, isOverview: false);
        }

        final scope = ShellScope.of(context);
        final sections = DeviceSections.of(
          context,
          scope.features,
          scope.featureContext,
          device,
        );
        for (final section in sections) {
          if (section.id == sectionId) {
            return (
              place: section.title,
              deviceName: device.device.name,
              isOverview: false,
            );
          }
        }

        return (
          place: l10n.sectionOverview,
          deviceName: device.device.name,
          isOverview: true,
        );
    }
  }
}
