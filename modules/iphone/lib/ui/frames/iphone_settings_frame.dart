import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/models/models.dart';
import 'package:iphone/ui/widgets/widgets.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The iPhone in Settings: what works and what doesn't before anything is
/// turned on, then pairing, picking the iPhone, the link's real state and
/// what to show. Looks again when the app comes back from the system's
/// Bluetooth settings.
class IphoneSettingsFrame extends StatefulWidget {
  const IphoneSettingsFrame({super.key});

  @override
  State<IphoneSettingsFrame> createState() => _IphoneSettingsFrameState();
}

class _IphoneSettingsFrameState extends State<IphoneSettingsFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<IphoneSettingsViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final host = context.select<IphoneSettingsViewModel, IphoneHostKind>(
      (viewModel) => viewModel.host,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SettingSwitchRow(
            title: l10n.settingsEnable,
            body: l10n.settingsEnableBody,
            value: enabled,
            onChanged: (value) => unawaited(viewModel.setEnabled(value)),
          ),
          if (enabled) const _Link(),
          Spacing.v8,
          NoticeBlock(
            title: l10n.worksTitle,
            body: l10n.worksBody,
            isProblem: false,
          ),
          Spacing.v8,
          NoticeBlock(
            title: l10n.limitsTitle,
            body: l10n.limitsBody,
            isProblem: false,
          ),
          if (host == .macos) ...[
            Spacing.v8,
            NoticeBlock(
              title: l10n.macNoteTitle,
              body: l10n.macNote,
              isProblem: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link();

  @override
  Widget build(BuildContext context) {
    final link = context.select<IphoneSettingsViewModel, LinkState>(
      (viewModel) => viewModel.link,
    );
    final openFailed = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    void openBluetooth() => unawaited(viewModel.openBluetoothSettings());
    void retry() => unawaited(viewModel.retry());
    final device = switch (link.deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => link.deviceName,
    };
    final content = switch (link.phase) {
      .off => const <Widget>[],
      .unsupported => [NoticeBlock(title: l10n.statusUnsupported)],
      .notConfigured => [NoticeBlock(title: l10n.statusNotConfigured)],
      .bluetoothOff => [
        NoticeBlock(
          title: l10n.problemBluetoothOffTitle,
          body: l10n.problemBluetoothOffBody,
          actionLabel: l10n.openBluetoothSettings,
          onAction: openBluetooth,
        ),
      ],
      .unauthorized => [
        NoticeBlock(
          title: l10n.problemUnauthorizedTitle,
          body: l10n.problemUnauthorizedBody,
          actionLabel: l10n.tryAgain,
          onAction: retry,
        ),
      ],
      .noDevice => const [_Pairing()],
      .connecting => [
        _Status(text: l10n.statusConnecting(device), color: palette.mutedText),
        const _Chosen(),
      ],
      .connected => [
        _Status(text: l10n.statusConnected(device), color: palette.success),
        const _Shared(),
        const _Chosen(),
      ],
      .outOfReach => [
        _Status(text: l10n.statusOutOfReach(device), color: palette.warning),
        const _Chosen(showRetry: true),
      ],
      .notShared => [
        NoticeBlock(
          title: l10n.problemNotSharedTitle(device),
          body: l10n.problemNotSharedBody(device),
          actionLabel: l10n.openBluetoothSettings,
          onAction: openBluetooth,
        ),
        const _Chosen(showRetry: true),
      ],
      .failed => [
        _Status(text: l10n.statusFailed(device), color: palette.danger),
        const _Chosen(showRetry: true),
      ],
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Spacing.v4,
        ...content,
        if (openFailed) ...[
          Spacing.v8,
          Text(
            l10n.openFailed,
            style: typography.caption1.copyWith(color: palette.danger),
          ),
        ],
        if (link.phase != .unsupported && link.phase != .notConfigured)
          const _Options(),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.fluffyTheme.typography.body2.copyWith(color: color),
  );
}

/// What a connected iPhone holds back, with the way to turn it on.
class _Shared extends StatelessWidget {
  const _Shared();

  @override
  Widget build(BuildContext context) {
    final notificationsNotShared = context
        .select<IphoneSettingsViewModel, bool>(
          (viewModel) => viewModel.notificationsNotShared,
        );
    final mediaNotShared = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.mediaNotShared,
    );
    final deviceName = context.select<IphoneSettingsViewModel, String>(
      (viewModel) => viewModel.link.deviceName,
    );
    final l10n = context.iphoneL10n;
    final device = switch (deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => deviceName,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (notificationsNotShared) ...[
          Spacing.v8,
          NoticeBlock(title: l10n.notificationsNotShared(device)),
        ],
        if (mediaNotShared) ...[
          Spacing.v8,
          NoticeBlock(title: l10n.mediaNotShared(device)),
        ],
      ],
    );
  }
}

/// Buttons under the chosen iPhone: try again, or pick another one.
class _Chosen extends StatelessWidget {
  const _Chosen({this.showRetry = false});

  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: Wrap(
        spacing: Spacing.d8,
        runSpacing: Spacing.d8,
        children: [
          if (showRetry)
            Button(
              variant: .ghost,
              label: l10n.tryAgain,
              onPressed: () => unawaited(viewModel.retry()),
            ),
          Button(
            variant: .ghost,
            label: l10n.forget,
            onPressed: () => unawaited(viewModel.forget()),
          ),
        ],
      ),
    );
  }
}

/// The pairing steps for this computer, and the paired devices to pick from.
class _Pairing extends StatelessWidget {
  const _Pairing();

  @override
  Widget build(BuildContext context) {
    final host = context.select<IphoneSettingsViewModel, IphoneHostKind>(
      (viewModel) => viewModel.host,
    );
    final devices = context.select<IphoneSettingsViewModel, List<BondedDevice>>(
      (viewModel) => viewModel.devices,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final pairStep = switch (host) {
      .windows => l10n.setupStepPairWindows,
      .macos => l10n.setupStepPairMac,
      .linux => l10n.setupStepPairLinux,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SetupSteps(
          title: l10n.setupTitle,
          steps: [
            l10n.setupStepUnlock,
            pairStep,
            l10n.setupStepAllow,
            l10n.setupStepChoose,
          ],
        ),
        Spacing.v8,
        Wrap(
          spacing: Spacing.d8,
          runSpacing: Spacing.d8,
          children: [
            Button(
              variant: .primary,
              label: l10n.openBluetoothSettings,
              onPressed: () => unawaited(viewModel.openBluetoothSettings()),
            ),
            Button(
              variant: .ghost,
              label: l10n.devicesRefresh,
              onPressed: () => unawaited(viewModel.loadDevices()),
            ),
          ],
        ),
        Spacing.v12,
        Text(
          l10n.devicesTitle,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
        if (devices.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: Spacing.d4),
            child: Text(
              l10n.devicesEmpty,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
          ),
        for (final device in devices)
          DeviceRow(
            key: ValueKey(device.id),
            name: switch (device.name.isEmpty) {
              true => l10n.deviceUnnamed,
              false => device.name,
            },
            detail: switch (device.connected) {
              true => l10n.deviceConnected,
              false => null,
            },
            actionLabel: l10n.deviceUse,
            onAction: () => unawaited(viewModel.choose(device)),
          ),
      ],
    );
  }
}

class _Options extends StatelessWidget {
  const _Options();

  @override
  Widget build(BuildContext context) {
    final showNotifications = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.showNotifications,
    );
    final showMedia = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.showMedia,
    );
    final hidePreviews = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.hidePreviews,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Spacing.v8,
        SettingSwitchRow(
          title: l10n.settingsNotifications,
          body: l10n.settingsNotificationsBody,
          value: showNotifications,
          onChanged: (value) =>
              unawaited(viewModel.setShowNotifications(value)),
        ),
        if (showNotifications)
          SettingSwitchRow(
            title: l10n.settingsHidePreviews,
            body: l10n.settingsHidePreviewsBody,
            value: hidePreviews,
            onChanged: (value) => unawaited(viewModel.setHidePreviews(value)),
          ),
        SettingSwitchRow(
          title: l10n.settingsMedia,
          body: l10n.settingsMediaBody,
          value: showMedia,
          onChanged: (value) => unawaited(viewModel.setShowMedia(value)),
        ),
      ],
    );
  }
}
