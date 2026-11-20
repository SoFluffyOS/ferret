import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings → Control → Keyboard and mouse: one switch for ⌃⌥→ and ⌃⌥⎋,
/// and what macOS still has to allow. Access is checked again when the app
/// comes back from System Settings.
class ScreenSwitchSettingsFrame extends StatefulWidget {
  const ScreenSwitchSettingsFrame({super.key});

  @override
  State<ScreenSwitchSettingsFrame> createState() =>
      _ScreenSwitchSettingsFrameState();
}

class _ScreenSwitchSettingsFrameState extends State<ScreenSwitchSettingsFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<ScreenSwitchViewModel>().checkAgain()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<ScreenSwitchViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final viewModel = context.read<ScreenSwitchViewModel>();
    final l10n = context.remoteInputL10n;

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.settingsScreenSwitch(ThisComputer.here),
          badge: BetaTag(
            .sharedInput,
            label: l10n.beta,
            tooltip: l10n.betaTooltip,
          ),
          body: l10n.settingsScreenSwitchBody,
          value: enabled,
          onChanged: (value) => unawaited(viewModel.setEnabled(value)),
        ),
        if (enabled) const GroupedCell(child: _Status()),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status();

  @override
  Widget build(BuildContext context) {
    final needsAccess = context.select<ScreenSwitchViewModel, bool>(
      (viewModel) => viewModel.needsAccess,
    );
    final keysTaken = context.select<ScreenSwitchViewModel, bool>(
      (viewModel) => viewModel.keysTaken,
    );
    final viewModel = context.read<ScreenSwitchViewModel>();
    final l10n = context.remoteInputL10n;

    if (needsAccess) {
      return NoticeBlock(
        title: l10n.settingsScreenAccess,
        body: l10n.settingsScreenAccessBody(ThisComputer.here),
        actionLabel: l10n.allowAccess,
        onAction: () => unawaited(viewModel.requestAccess()),
        isProblem: false,
      );
    }

    if (keysTaken) {
      return NoticeBlock(title: l10n.settingsScreenKeysTaken);
    }

    final names = context.select<ScreenSwitchViewModel, String>(
      (viewModel) => viewModel.targetNames.join(' → '),
    );
    final style = context.fluffyTheme.typography.caption1;
    if (names.isEmpty) {
      return Text(
        l10n.settingsScreenNoTarget,
        style: style.copyWith(color: context.palette.mutedText),
      );
    }

    return Text(
      l10n.settingsScreenNext(names),
      style: style.copyWith(color: context.palette.success),
    );
  }
}
