import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// On Android: the steps that keep Ferret connected, each explained first
/// with its fix as a button. Hides itself once everything is set.
class StayConnectedCard extends StatefulWidget {
  const StayConnectedCard({super.key});

  @override
  State<StayConnectedCard> createState() => _StayConnectedCardState();
}

class _StayConnectedCardState extends State<StayConnectedCard>
    with WidgetsBindingObserver {
  final StayConnectedViewModel _viewModel = .new();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_viewModel.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) {
      unawaited(_viewModel.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_viewModel.isAndroid) {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _Steps(),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final (
      :notificationsAllowed,
      :batteryExempt,
      :maker,
      :stopsToday,
      :canAddTile,
      :allSet,
    ) = context.select(
      (StayConnectedViewModel viewModel) => (
        notificationsAllowed: viewModel.notificationsAllowed,
        batteryExempt: viewModel.batteryExempt,
        maker: viewModel.maker,
        stopsToday: viewModel.stopsToday,
        canAddTile: viewModel.canAddTile,
        allSet: viewModel.allSet,
      ),
    );
    if (allSet) {
      return const SizedBox.shrink();
    }

    final viewModel = context.read<StayConnectedViewModel>();

    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.batteryCharging,
                  size: Spacing.d20,
                  color: palette.accent,
                ),
                Spacing.h8,
                Expanded(
                  child: Text(
                    l10n.stayTitle,
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                ),
              ],
            ),
            Spacing.v6,
            Text(
              l10n.stayBody,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            if (stopsToday > 0) ...[
              Spacing.v8,
              Text(
                l10n.stayStops(stopsToday),
                style: typography.caption1.copyWith(color: palette.danger),
              ),
            ],
            if (!notificationsAllowed)
              _Step(
                text: l10n.stayNotifications,
                fix: l10n.stayNotificationsFix,
                onFix: viewModel.allowNotifications,
              ),
            if (!batteryExempt)
              _Step(
                text: l10n.stayBattery,
                fix: l10n.stayBatteryFix,
                onFix: viewModel.allowBackground,
              ),
            if (maker.hasExtraKiller && (stopsToday > 0 || !batteryExempt))
              _Step(
                text: l10n.stayMaker(_makerName(maker)),
                fix: l10n.stayMakerFix,
                onFix: viewModel.openMakerSettings,
              ),
            if (canAddTile)
              _Step(
                text: l10n.stayTile,
                fix: l10n.stayTileFix,
                onFix: viewModel.addTile,
              ),
          ],
        ),
      ),
    );
  }

  String _makerName(DeviceMaker maker) => switch (maker) {
    .xiaomi => 'Xiaomi',
    .samsung => 'Samsung',
    .oneplus => 'OnePlus',
    .huawei => 'Huawei',
    .oppo => 'OPPO',
    .vivo => 'vivo',
    .other => '',
  };
}

class _Step extends StatelessWidget {
  const _Step({required this.text, required this.fix, required this.onFix});

  final String text;
  final String fix;
  final Future<void> Function() onFix;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.fluffyTheme.typography.body2.copyWith(
                color: palette.text,
              ),
            ),
          ),
          Spacing.h12,
          Button(variant: .secondary, label: fix, onPressed: onFix),
        ],
      ),
    );
  }
}
