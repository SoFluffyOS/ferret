import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// Home's last line, which changes with what is true: paused and until
/// when, nobody to send to, that files can be dragged onto a device, or
/// on an iPhone that Ferret only syncs while it is open.
/// It sits at the bottom so the device list never jumps.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isPaused = context.select<PauseController, bool>(
      (controller) => controller.isPaused,
    );
    final until = context.select<PauseController, DateTime?>(
      (controller) => controller.until,
    );
    final hasDevices = context.select<EngineHost, bool>(
      (host) => host.devices.isNotEmpty,
    );
    final hasConnected = context.select<EngineHost, bool>(
      (host) => host.connectedCount > 0,
    );
    final isReconnecting = context.select<EngineHost, bool>(
      (host) => host.devices.any((status) => status.isReconnecting),
    );
    final l10n = context.shellL10n;

    if (isPaused) {
      return FooterHint(
        text: switch (until) {
          final until? => l10n.footerPausedUntil(
            ClockText.timeOfDay(l10n.localeName, until),
          ),
          null => l10n.footerPaused,
        },
        actionLabel: l10n.resume,
        onAction: () => context.read<PauseController>().resume(),
      );
    }

    if (!hasDevices) {
      return const SizedBox.shrink();
    }

    if (!hasConnected && isReconnecting) {
      return const SizedBox.shrink();
    }

    if (!hasConnected) {
      return FooterHint(text: l10n.footerNobody);
    }

    if (defaultTargetPlatform == .iOS) {
      return FooterHint(text: l10n.footerKeepOpen);
    }

    final dragsFiles = switch (defaultTargetPlatform) {
      .macOS || .windows || .linux => true,
      _ => false,
    };
    if (!dragsFiles) {
      return const SizedBox.shrink();
    }

    return FooterHint(text: l10n.footerDrag);
  }
}
