import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Mirroring settings on a computer: each connected phone's status, its
/// "pause while using" switch and its app picker.
class PhonesSettingsFrame extends StatelessWidget {
  const PhonesSettingsFrame({super.key, required this.onChooseApps});

  final ValueChanged<PhoneStatus> onChooseApps;

  @override
  Widget build(BuildContext context) {
    final phones = context.select<PhonesViewModel, List<PhoneStatus>>(
      (viewModel) => viewModel.phones,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;

    if (phones.isEmpty) {
      return SurfaceCard(
        child: Text(
          l10n.noPhone,
          style: typography.body2.copyWith(color: palette.mutedText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final phone in phones)
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d8),
            child: _PhoneCard(
              phone: phone,
              onChooseApps: () => onChooseApps(phone),
            ),
          ),
      ],
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.phone, required this.onChooseApps});

  final PhoneStatus phone;
  final VoidCallback onChooseApps;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PhonesViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final settings = phone.settings;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            phone.name,
            style: typography.base1.copyWith(color: palette.text),
          ),
          Spacing.v4,
          PhoneStatusLine(phone: phone),
          if (phone.unreachable) ...[
            Spacing.v8,
            Button(
              variant: .secondary,
              label: l10n.tryAgain,
              onPressed: () => viewModel.retry(phone.deviceId),
            ),
          ],
          if (settings != null && settings.enabled) ...[
            Spacing.v12,
            ToggleRow(
              title: l10n.skipWhileUsing,
              detail: l10n.skipWhileUsingDetail,
              value: settings.skipWhileUsing,
              onChanged: (value) =>
                  viewModel.setSkipWhileUsing(phone.deviceId, value),
            ),
            Spacing.v12,
            Button(
              variant: .secondary,
              label: l10n.chooseApps,
              onPressed: onChooseApps,
            ),
          ],
        ],
      ),
    );
  }
}
