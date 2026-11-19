import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/ui/widgets/widgets.dart';
import 'package:find/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Find my device in Settings: ringing on silent and what it needs on this
/// platform, the torch, honest limits, and a test ring. Permissions are read
/// again when the app comes back from system settings.
class FindSettingsFrame extends StatefulWidget {
  const FindSettingsFrame({super.key});

  @override
  State<FindSettingsFrame> createState() => _FindSettingsFrameState();
}

class _FindSettingsFrameState extends State<FindSettingsFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<FindSettingsViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = context.select<FindSettingsViewModel, FindPlatformKind>(
      (viewModel) => viewModel.platform,
    );
    final abilities = context.select<FindSettingsViewModel, RingAbilities>(
      (viewModel) => viewModel.abilities,
    );
    final flashTorch = context.select<FindSettingsViewModel, bool>(
      (viewModel) => viewModel.flashTorch,
    );
    final viewModel = context.read<FindSettingsViewModel>();
    final l10n = context.findL10n;
    final showsVolumeSwitch =
        platform == .android ||
        (platform == .macos && abilities.controlsVolume);

    return GroupedCard(
      children: [
        if (showsVolumeSwitch) _RingOnSilent(platform: platform),
        if (abilities.hasTorch)
          SettingSwitchRow(
            title: l10n.settingsFlashTorch,
            body: l10n.settingsFlashTorchBody,
            value: flashTorch,
            onChanged: (value) => unawaited(viewModel.setFlashTorch(value)),
          ),
        if (platform == .android && !abilities.fullScreenAllowed)
          GroupedCell(
            child: NoticeBlock(
              title: l10n.settingsFullScreenOff,
              body: l10n.settingsFullScreenHowTo,
              actionLabel: l10n.settingsAllow,
              onAction: () => unawaited(viewModel.openFullScreen()),
            ),
          ),
        ..._limits(l10n, platform, abilities),
        GroupedCell(
          child: Button(
            variant: .ghost,
            label: l10n.settingsTestRing,
            tooltip: l10n.settingsTestRingBody,
            onPressed: () => unawaited(viewModel.testRing()),
          ),
        ),
      ],
    );
  }

  List<Widget> _limits(
    FindLocalizations l10n,
    FindPlatformKind platform,
    RingAbilities abilities,
  ) {
    if (!abilities.canPlaySound) {
      return [
        GroupedCell(child: NoticeBlock(title: l10n.settingsLimitNoPlayer)),
      ];
    }

    final limit = switch (platform) {
      .ios => l10n.settingsLimitIos,
      .desktop => l10n.settingsLimitDesktop,
      _ => null,
    };
    if (limit == null) {
      return const [];
    }

    return [
      GroupedCell(
        child: NoticeBlock(title: limit, isProblem: false),
      ),
    ];
  }
}

class _RingOnSilent extends StatelessWidget {
  const _RingOnSilent({required this.platform});

  final FindPlatformKind platform;

  @override
  Widget build(BuildContext context) {
    final ringOnSilent = context.select<FindSettingsViewModel, bool>(
      (viewModel) => viewModel.ringOnSilent,
    );
    final needsDndAccess = context.select<FindSettingsViewModel, bool>(
      (viewModel) => viewModel.needsDndAccess,
    );
    final stillOff = context.select<FindSettingsViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final openFailed = context.select<FindSettingsViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final viewModel = context.read<FindSettingsViewModel>();
    final l10n = context.findL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final isAndroid = platform == .android;
    final body = switch (isAndroid) {
      true => l10n.settingsRingOnSilentAndroid,
      false => l10n.settingsRingOnSilentMac,
    };
    final dndTitle = switch (stillOff) {
      true => l10n.settingsDndStillOff,
      false => l10n.settingsDndOff,
    };

    final notes = [
      if (isAndroid && needsDndAccess)
        NoticeBlock(
          title: dndTitle,
          body: l10n.settingsDndHowTo,
          actionLabel: l10n.settingsAllow,
          onAction: () => unawaited(viewModel.openDndAccess()),
        ),
      if (isAndroid && ringOnSilent && !needsDndAccess)
        Text(
          l10n.settingsDndOn,
          style: typography.caption1.copyWith(color: palette.success),
        ),
      if (openFailed)
        Text(
          l10n.settingsOpenFailed,
          style: typography.caption1.copyWith(color: palette.danger),
        ),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        SettingSwitchRow(
          title: l10n.settingsRingOnSilent,
          body: body,
          value: ringOnSilent,
          onChanged: (value) => unawaited(viewModel.setRingOnSilent(value)),
        ),
        for (final note in notes)
          Padding(
            padding: EdgeInsets.only(
              left: PageInsets.row,
              right: PageInsets.row,
              bottom: Spacing.d12,
            ),
            child: note,
          ),
      ],
    );
  }
}
