import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/view_models/view_models.dart';

/// Names the window after what it shows ("Pixel 9 — Messages"), never just
/// after the app. [onTitle] hears each new title.
class WindowTitleFrame extends StatefulWidget {
  const WindowTitleFrame({
    super.key,
    required this.onTitle,
    required this.child,
  });

  final void Function(String title) onTitle;
  final Widget child;

  @override
  State<WindowTitleFrame> createState() => _WindowTitleFrameState();
}

class _WindowTitleFrameState extends State<WindowTitleFrame> {
  String? _told;

  @override
  Widget build(BuildContext context) {
    final title = _title(context);
    if (title != _told) {
      _told = title;
      scheduleMicrotask(() => widget.onTitle(title));
    }

    return widget.child;
  }

  String _title(BuildContext context) {
    final l10n = context.shellL10n;
    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => viewModel.selection,
    );
    final device = context.select<EngineHost, DeviceStatus?>(
      (host) => switch (selection) {
        DeviceDestination(:final deviceId) => host.statusOf(deviceId),
        _ => null,
      },
    );

    switch (selection) {
      case null:
        return l10n.appName;
      case ActivityDestination():
        return l10n.activityTitle;
      case SettingsDestination():
        return l10n.settingsTitle;
      case DeviceDestination(:final sectionId):
        if (device == null) {
          return l10n.appName;
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
            return l10n.windowTitleSection(device.device.name, section.title);
          }
        }

        return device.device.name;
    }
  }
}
