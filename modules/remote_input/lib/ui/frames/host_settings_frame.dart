import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This computer's remote input settings: on or off, what it needs on this
/// platform with a fix button, devices allowed for good with Revoke, and
/// the history of who controlled it. Access is checked again when the app
/// comes back from system settings.
class HostSettingsFrame extends StatefulWidget {
  const HostSettingsFrame({super.key});

  /// How many past times the history shows.
  static const historyShown = 5;

  @override
  State<HostSettingsFrame> createState() => _HostSettingsFrameState();
}

class _HostSettingsFrameState extends State<HostSettingsFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<HostViewModel>().checkAgain()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<HostViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final status = context.select<HostViewModel, InjectorStatus?>(
      (viewModel) => viewModel.status,
    );
    final viewModel = context.read<HostViewModel>();
    final l10n = context.remoteInputL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SettingSwitchRow(
            title: l10n.settingsEnabled,
            body: l10n.settingsEnabledBody,
            value: enabled,
            onChanged: (value) => unawaited(viewModel.setEnabled(value)),
          ),
          if (enabled && status != null) ...[
            Spacing.v8,
            _Status(status: status),
          ],
          const _Allowed(),
          const _History(),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});

  final InjectorStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<HostViewModel>();
    if (status.isReady) {
      return Text(
        l10n.statusLine(status),
        style: context.fluffyTheme.typography.caption1.copyWith(
          color: context.palette.success,
        ),
      );
    }

    final (actionLabel, action) = switch (status.state) {
      .needsPermission => (l10n.allowAccess, viewModel.requestAccess),
      _ => (l10n.checkAgain, viewModel.checkAgain),
    };

    return NoticeBlock(
      title: l10n.statusLine(status),
      body: l10n.statusFix(status),
      actionLabel: actionLabel,
      onAction: () => unawaited(action()),
    );
  }
}

class _Allowed extends StatelessWidget {
  const _Allowed();

  @override
  Widget build(BuildContext context) {
    final allowed = context.select<HostViewModel, List<AllowedDevice>>(
      (viewModel) => viewModel.allowedDevices,
    );
    final viewModel = context.read<HostViewModel>();
    final l10n = context.remoteInputL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsAllowedTitle),
        if (allowed.isEmpty)
          Text(
            l10n.settingsAllowedEmpty,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        for (final device in allowed)
          Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: typography.body2.copyWith(color: palette.text),
                  overflow: .ellipsis,
                ),
              ),
              Button(
                variant: .ghost,
                label: l10n.revoke,
                onPressed: () => unawaited(viewModel.revoke(device.id)),
              ),
            ],
          ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final history = context.select<HostViewModel, List<ControlRecord>>(
      (viewModel) => viewModel.history,
    );
    final viewModel = context.read<HostViewModel>();
    final l10n = context.remoteInputL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsHistoryTitle),
        if (history.isEmpty)
          Text(
            l10n.settingsHistoryEmpty,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        for (final record in history.take(HostSettingsFrame.historyShown))
          Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.d2),
            child: Text(
              l10n.audit(record),
              style: typography.body2.copyWith(color: palette.text),
            ),
          ),
        if (history.isNotEmpty) ...[
          Spacing.v8,
          Button(
            variant: .secondary,
            label: l10n.clearHistory,
            onPressed: () => unawaited(viewModel.clearHistory()),
          ),
        ],
      ],
    );
  }
}
