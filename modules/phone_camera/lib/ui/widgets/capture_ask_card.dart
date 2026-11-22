import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phone_camera/l10n/l10n.dart';
import 'package:phone_camera/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "MacBook Air wants a photo", with Take photo and Not now. Nothing is
/// captured until the owner presses the camera's shutter.
class CaptureAskCard extends StatelessWidget {
  const CaptureAskCard({
    super.key,
    required this.ask,
    required this.deviceName,
    required this.onTake,
    required this.onDecline,
  });

  final CaptureAsk ask;
  final String deviceName;
  final VoidCallback onTake;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.cameraL10n;
    final (title, takeLabel, icon) = switch (ask.kind) {
      .photo => (
        l10n.askPhotoTitle(deviceName),
        l10n.askTakePhoto,
        LucideIcons.camera,
      ),
      .document => (
        l10n.askDocumentTitle(deviceName),
        l10n.askScan,
        LucideIcons.scanLine,
      ),
    };

    return FeatureCard(
      icon: icon,
      iconTone: .accent,
      title: title,
      announces: true,
      subtitle: switch (ask.isCapturing) {
        true => l10n.askCapturing,
        false => l10n.askBody,
      },
      actions: [
        Button(
          label: takeLabel,
          variant: .primary,
          mainAxisSize: .min,
          onPressed: switch (ask.isCapturing) {
            true => null,
            false => onTake,
          },
        ),
        GhostButton(
          label: l10n.askNotNow,
          mainAxisSize: .min,
          onPressed: switch (ask.isCapturing) {
            true => null,
            false => onDecline,
          },
        ),
      ],
    );
  }
}
