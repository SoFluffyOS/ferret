import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A window's content pane as a drop target: files dropped on it go to the
/// device it shows, or to every connected device on Activity and Settings.
/// While they are over it, the pane dims under one card that says where
/// they would go, and the page stays where it was, inert.
class PaneDropFrame extends StatelessWidget {
  const PaneDropFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => viewModel.selection,
    );
    final target = _targetFor(devices, selection);
    final isHovered = context.select<OsDropViewModel, bool>(
      (drop) => target != null && drop.hovered == PaneDropTarget(target),
    );
    if (target == null) {
      return child;
    }

    final connectedCount = devices.where((status) => status.isConnected).length;

    return DropTargetRegion(
      target: PaneDropTarget(target),
      child: Stack(
        fit: .expand,
        children: [
          // Under the hint the page is a dimmed backdrop: nothing on it can
          // be read or pressed until the files are dropped or taken away,
          // so for that moment it isn't there for a screen reader either.
          ExcludeSemantics(excluding: isHovered, child: child),
          if (isHovered)
            Positioned.fill(
              child: IgnorePointer(
                child: _Hint(target: target, connectedCount: connectedCount),
              ),
            ),
        ],
      ),
    );
  }

  FilesDropTarget? _targetFor(
    List<DeviceStatus> devices,
    WindowDestination? selection,
  ) {
    if (selection case DeviceDestination(:final deviceId)) {
      for (final status in devices) {
        if (status.device.id == deviceId) {
          return WindowDropTargets.device(status);
        }
      }
    }

    return WindowDropTargets.everyone(devices);
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.target, required this.connectedCount});

  final FilesDropTarget target;
  final int connectedCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final label = switch (target) {
      DeviceDropTarget(isConnected: false, :final name) =>
        l10n.dropDeviceOffline(name),
      DeviceDropTarget(:final name) => l10n.dropSendTo(name),
      AllDevicesDropTarget() ||
      PaneDropTarget() ||
      ReceiverDropTarget() => l10n.dropSendToAll(
        connectedCount,
      ),
    };
    final icon = switch (target) {
      DeviceDropTarget(isConnected: false) => LucideIcons.wifiOff,
      _ => LucideIcons.upload,
    };

    return ColoredBox(
      color: palette.background.withValues(alpha: 0.7),
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: SurfaceCard(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d24,
              vertical: Spacing.d16,
            ),
            child: Row(
              mainAxisSize: .min,
              children: [
                Icon(icon, size: Spacing.d24, color: palette.text),
                Spacing.h12,
                Flexible(
                  child: Text(
                    label,
                    style: typography.base1.copyWith(
                      color: palette.text,
                      fontWeight: .w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
