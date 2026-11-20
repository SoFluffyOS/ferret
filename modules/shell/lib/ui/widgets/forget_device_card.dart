import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Where to forget a device.
enum ForgetScope { everywhere, here }

/// Forgetting a device, at the bottom of its page: one quiet line that
/// opens, in place, into the question and its answers. Nothing floats over
/// the page.
///
/// When the device is one of several that share pairings, removing it from
/// all of them is what people mean most of the time, so that is the main
/// button.
class ForgetDeviceCard extends StatefulWidget {
  const ForgetDeviceCard({
    super.key,
    required this.deviceName,
    required this.here,
    required this.sharedWithOthers,
    required this.onForget,
  });

  final String deviceName;

  /// What to call the device Ferret runs on, such as "this Mac".
  final String here;

  /// Whether the user's other devices know this one too.
  final bool sharedWithOthers;
  final ValueChanged<ForgetScope> onForget;

  @override
  State<ForgetDeviceCard> createState() => _ForgetDeviceCardState();
}

class _ForgetDeviceCardState extends State<ForgetDeviceCard> {
  bool _asking = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final name = widget.deviceName;

    if (!_asking) {
      return Tappable(
        onTap: () => setState(() => _asking = true),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PageInsets.row,
            vertical: Spacing.d12,
          ),
          child: Text(
            l10n.deviceForget(name),
            style: typography.base2.copyWith(color: palette.danger),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              l10n.deviceForgetConfirmTitle(name),
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.v4,
            Text(
              switch (widget.sharedWithOthers) {
                true => l10n.deviceForgetScopeBody(name),
                false => l10n.deviceForgetConfirmBody(name, widget.here),
              },
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
            Spacing.v12,
            Button(
              variant: .primary,
              color: palette.danger,
              label: switch (widget.sharedWithOthers) {
                true => l10n.deviceForgetEverywhereShort,
                false => l10n.deviceForgetShort,
              },
              tooltip: switch (widget.sharedWithOthers) {
                true => l10n.deviceForgetEverywhere,
                false => l10n.deviceForget(name),
              },
              semanticLabel: switch (widget.sharedWithOthers) {
                true => l10n.deviceForgetEverywhere,
                false => l10n.deviceForget(name),
              },
              onPressed: () =>
                  widget.onForget(switch (widget.sharedWithOthers) {
                    true => ForgetScope.everywhere,
                    false => ForgetScope.here,
                  }),
            ),
            if (widget.sharedWithOthers) ...[
              Spacing.v8,
              GhostButton(
                label: l10n.deviceForgetHereShort,
                tooltip: l10n.deviceForgetHere(widget.here),
                semanticLabel: l10n.deviceForgetHere(widget.here),
                onPressed: () => widget.onForget(ForgetScope.here),
              ),
            ],
            Spacing.v8,
            GhostButton(
              label: l10n.cancel,
              onPressed: () => setState(() => _asking = false),
            ),
          ],
        ),
      ),
    );
  }
}
