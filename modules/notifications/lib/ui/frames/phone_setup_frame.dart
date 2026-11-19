import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Mirroring settings on the phone: the explainer, notification access with
/// a re-check on return, the restricted settings guide, and the options.
class PhoneSetupFrame extends StatefulWidget {
  const PhoneSetupFrame({super.key, required this.onChooseApps});

  final VoidCallback onChooseApps;

  @override
  State<PhoneSetupFrame> createState() => _PhoneSetupFrameState();
}

class _PhoneSetupFrameState extends State<PhoneSetupFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<MirrorSetupViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.select<MirrorSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );

    return switch (stage) {
      .off => const _Explainer(),
      .needsAccess => const _NeedsAccess(),
      .ready => _Ready(onChooseApps: widget.onChooseApps),
    };
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final l10n = context.notificationsL10n;

    return GroupedCard(
      children: [
        GroupedRow(title: l10n.explainer, subtitle: l10n.explainerDetail),
        GroupedCell(
          child: Button(
            variant: .primary,
            label: l10n.turnOn,
            onPressed: context.read<MirrorSetupViewModel>().turnOn,
          ),
        ),
      ],
    );
  }
}

class _NeedsAccess extends StatelessWidget {
  const _NeedsAccess();

  @override
  Widget build(BuildContext context) {
    final stillOff = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final restricted = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.restricted,
    );
    final openFailed = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final viewModel = context.read<MirrorSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final status = switch (stillOff) {
      true => l10n.accessStillOff,
      false => l10n.accessOff,
    };

    return GroupedCard(
      children: [
        GroupedCell(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              StatusLine(text: status, tone: .warning),
              Spacing.v4,
              Text(
                l10n.accessHowTo,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
              if (openFailed) ...[
                Spacing.v8,
                Text(
                  l10n.openSettingsFailed,
                  style: typography.caption1.copyWith(color: palette.danger),
                ),
              ],
              Spacing.v12,
              Button(
                variant: .primary,
                label: l10n.openAccessSettings,
                onPressed: viewModel.openAccessSettings,
              ),
            ],
          ),
        ),
        if (restricted)
          GroupedCell(
            child: RestrictedGuide(onOpenAppInfo: viewModel.openAppInfo),
          ),
        GroupedCell(
          child: Button(
            variant: .ghost,
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.onChooseApps});

  final VoidCallback onChooseApps;

  @override
  Widget build(BuildContext context) {
    final skipWhileUsing = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.skipWhileUsing,
    );
    final appFilter = context.select<MirrorSetupViewModel, AppFilter>(
      (viewModel) => viewModel.appFilter,
    );
    final appCount = context.select<MirrorSetupViewModel, int>(
      (viewModel) => viewModel.namedAppCount,
    );
    final viewModel = context.read<MirrorSetupViewModel>();
    final l10n = context.notificationsL10n;

    return GroupedCard(
      children: [
        GroupedCell(
          child: StatusLine(text: l10n.accessOn, tone: .good),
        ),
        SettingSwitchRow(
          title: l10n.skipWhileUsing,
          body: l10n.skipWhileUsingDetail,
          value: skipWhileUsing,
          onChanged: viewModel.setSkipWhileUsing,
        ),
        GroupedCell(
          child: Button(
            variant: .ghost,
            label:
                '${l10n.chooseApps} · ${l10n.appsSummary(appFilter, appCount)}',
            onPressed: onChooseApps,
          ),
        ),
        GroupedCell(
          child: Button(
            variant: .ghost,
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ),
      ],
    );
  }
}
