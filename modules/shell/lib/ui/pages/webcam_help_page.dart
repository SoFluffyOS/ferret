import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How to use an Android phone as this computer's webcam with the phone's
/// own USB webcam mode; over Wi-Fi, Ferret shows the camera in its own
/// window only.
class WebcamHelpPage extends StatelessWidget {
  const WebcamHelpPage({
    super.key,
    required this.deviceName,
    required this.here,
  });

  final String deviceName;

  /// This computer's kind, for `{here, select, …}`.
  final String here;

  /// Android 14 and later can be a USB webcam on many phones, and a
  /// computer is what it plugs into.
  static bool fits(TrustedDevice device, LocalDevice here) {
    final isAndroidPhone =
        device.platform == .PLATFORM_ANDROID &&
        device.formFactor == .FORM_FACTOR_PHONE;
    final isComputer = switch (here.formFactor) {
      .FORM_FACTOR_LAPTOP || .FORM_FACTOR_DESKTOP => true,
      _ => false,
    };

    return isAndroidPhone && isComputer;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final body = typography.body2.copyWith(color: palette.text);
    final muted = typography.base2.copyWith(color: palette.mutedText);

    return FerretPage(
      title: l10n.webcamTitle(deviceName),
      backLabel: l10n.back,
      children: [
        Text(l10n.webcamIntro, style: body),
        Spacing.v12,
        SurfaceCard(
          child: Text(l10n.webcamSteps(deviceName, here), style: body),
        ),
        Spacing.v12,
        Text(l10n.webcamMissing(deviceName), style: muted),
        Spacing.v8,
        Text(l10n.webcamOverWifi(deviceName), style: muted),
      ],
    );
  }
}
