import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Where to forget a device.
enum ForgetScope { everywhere, here }

/// Asks whether a device should leave all the user's devices or only this
/// one. Removing it everywhere is what people mean most of the time, so it
/// is the main button.
class ForgetDeviceDialog extends StatelessWidget {
  const ForgetDeviceDialog({super.key, required this.deviceName});

  final String deviceName;

  /// The scope the user chose, or null when they kept the device.
  static Future<ForgetScope?> show(BuildContext context, String deviceName) =>
      showGeneralDialog<ForgetScope>(
        context: context,
        barrierDismissible: true,
        barrierLabel: context.shellL10n.cancel,
        barrierColor: const Color(0x99000000),
        pageBuilder: (_, _, _) => ForgetDeviceDialog(deviceName: deviceName),
      );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final navigator = Navigator.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d320),
        child: SurfaceCard(
          padding: EdgeInsets.all(Spacing.d20),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.deviceForgetConfirmTitle(deviceName),
                textAlign: .center,
                style: typography.title3.copyWith(color: palette.text),
              ),
              Spacing.v8,
              Text(
                l10n.deviceForgetScopeBody(deviceName),
                textAlign: .center,
                style: typography.body2.copyWith(color: palette.mutedText),
              ),
              Spacing.vertical(Spacing.d20),
              Button(
                variant: .primary,
                color: palette.danger,
                label: l10n.deviceForgetEverywhere,
                onPressed: () => navigator.pop(ForgetScope.everywhere),
              ),
              Spacing.v8,
              Button(
                variant: .ghost,
                label: l10n.deviceForgetHere,
                onPressed: () => navigator.pop(ForgetScope.here),
              ),
              Spacing.v8,
              Button(
                variant: .ghost,
                label: l10n.cancel,
                onPressed: navigator.pop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
