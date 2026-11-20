import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Notifications in a computer's Settings: how each paired phone is doing,
/// and where its own choices are.
class PhonesSettingsFrame extends StatelessWidget {
  const PhonesSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final phones = context.select<PhonesViewModel, List<PhoneStatus>>(
      (viewModel) => viewModel.pairedPhones,
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
        GroupedCard(
          children: [for (final phone in phones) _PhoneRow(phone: phone)],
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            PageInsets.row,
            Spacing.d8,
            PageInsets.row,
            0,
          ),
          child: Text(
            l10n.settingsPerPhone,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});

  final PhoneStatus phone;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PhonesViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;

    return GroupedCell(
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
            GhostButton(
              label: l10n.tryAgain,
              onPressed: () => viewModel.retry(phone.deviceId),
            ),
          ],
        ],
      ),
    );
  }
}
