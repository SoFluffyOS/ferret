import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The body of "What Pixel 7 can use": what that means, one switch per
/// feature, and turning everything off at once.
class DeviceAccessFrame extends StatelessWidget {
  const DeviceAccessFrame({
    super.key,
    required this.deviceName,
    required this.here,
    required this.isConnected,
    required this.features,
  });

  final String deviceName;

  /// What to call the device Ferret runs on, such as "this Mac".
  final String here;
  final bool isConnected;
  final List<FeatureUi> features;

  @override
  Widget build(BuildContext context) {
    final allOff = context.select<DeviceAccessViewModel, bool>(
      (viewModel) => viewModel.allOff,
    );
    final viewModel = context.read<DeviceAccessViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final note = typography.base2.copyWith(color: palette.mutedText);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
          child: Text(l10n.accessIntro(deviceName, here), style: note),
        ),
        if (!isConnected) ...[
          Spacing.v8,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
            child: Text(l10n.accessOffline(deviceName), style: note),
          ),
        ],
        Spacing.v16,
        GroupedCard(
          separatorIndent: PageInsets.row + IconTile.size + Spacing.d12,
          children: [
            for (final feature in features) _AccessRow(feature: feature),
          ],
        ),
        Spacing.v16,
        Row(
          children: [
            Button(
              variant: .ghost,
              mainAxisSize: .min,
              label: switch (allOff) {
                true => l10n.accessTurnAllOn,
                false => l10n.accessTurnAllOff,
              },
              onPressed: () => unawaited(switch (allOff) {
                true => viewModel.turnAllOn(),
                false => viewModel.turnAllOff(),
              }),
            ),
          ],
        ),
        Spacing.v8,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
          child: Text(
            l10n.accessForgetHint(deviceName),
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ),
      ],
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.feature});

  final FeatureUi feature;

  @override
  Widget build(BuildContext context) {
    final featureId = feature.featureId;
    final allowed = context.select<DeviceAccessViewModel, bool>(
      (viewModel) => viewModel.isAllowed(featureId),
    );
    final viewModel = context.read<DeviceAccessViewModel>();

    return MergeSemantics(
      child: GroupedRow(
        title: feature.title(context),
        subtitle: FeatureAccess.describe(context.shellL10n, featureId),
        leading: IconTile(
          icon: feature.icon,
          color: feature.settingsGroup.place.color,
        ),
        trailing: SwitchToggle(
          value: allowed,
          onChanged: (value) =>
              unawaited(viewModel.setAllowed(featureId, value)),
        ),
      ),
    );
  }
}
