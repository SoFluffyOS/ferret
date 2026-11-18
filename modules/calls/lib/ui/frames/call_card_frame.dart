import 'package:calls/l10n/l10n.dart';
import 'package:calls/models/models.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on a computer: one card per call that is ringing or going
/// on on a connected phone, and nothing otherwise.
class CallCardFrame extends StatelessWidget {
  const CallCardFrame({super.key, this.deviceId});

  /// Only the calls of this phone, as on its Calls section.
  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final calls = context.select<ActiveCallsViewModel, List<RemoteCall>>(
      (viewModel) => [
        for (final call in viewModel.calls)
          if (deviceId == null || call.deviceId == deviceId) call,
      ],
    );
    if (calls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, call) in calls.indexed) ...[
          if (index > 0) Spacing.v8,
          _CallCard(key: ValueKey(call.key), call: call),
        ],
      ],
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({super.key, required this.call});

  final RemoteCall call;

  @override
  Widget build(BuildContext context) {
    final problem = context.select<ActiveCallsViewModel, CommandOutcome?>(
      (viewModel) => viewModel.problemOf(call),
    );
    final busy = context.select<ActiveCallsViewModel, bool>(
      (viewModel) => viewModel.isBusy(call),
    );
    final silenced = context.select<ActiveCallsViewModel, bool>(
      (viewModel) => viewModel.isSilenced(call),
    );
    final viewModel = context.read<ActiveCallsViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final details = call.call;
    final subtitle = [
      if (details.contactName.isNotEmpty && details.number.isNotEmpty)
        details.number,
      l10n.stateOf(call),
    ].join(' · ');
    final hangUp = Button(
      mainAxisSize: .min,
      variant: .primary,
      color: palette.danger,
      label: l10n.hangUp,
      icon: Icon(LucideIcons.phoneOff, size: Spacing.d16),
      enable: !busy,
      onPressed: () => viewModel.end(call),
    );
    final ringingActions = [
      Button(
        mainAxisSize: .min,
        variant: .primary,
        color: palette.success,
        label: l10n.answer,
        icon: Icon(LucideIcons.phone, size: Spacing.d16),
        enable: !busy,
        onPressed: () => viewModel.answer(call),
      ),
      Button(
        mainAxisSize: .min,
        variant: .ghost,
        label: l10n.decline,
        icon: Icon(LucideIcons.phoneOff, size: Spacing.d16),
        enable: !busy,
        onPressed: () => viewModel.end(call),
      ),
      Button(
        mainAxisSize: .min,
        variant: .ghost,
        label: switch (silenced) {
          true => l10n.silenced,
          false => l10n.silence,
        },
        icon: Icon(LucideIcons.bellOff, size: Spacing.d16),
        enable: !busy && !silenced,
        onPressed: () => viewModel.silence(call),
      ),
    ];

    return FeatureCard(
      icon: LucideIcons.phone,
      title: l10n.callerOf(details),
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (!call.isRinging) ...[
            CallTimer(
              since: call.timerStart,
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.h12,
          ],
          CallerAvatar(photoJpeg: details.photoJpeg),
        ],
      ),
      children: [
        Text(
          l10n.audioStays(call.deviceName),
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
        if (problem case final problem?) ...[
          Spacing.v6,
          Text(
            l10n.outcomeText(problem, call.deviceName),
            style: typography.caption1.copyWith(color: palette.danger),
          ),
        ],
      ],
      actions: switch (call.isRinging) {
        true => ringingActions,
        false => [hangUp],
      },
    );
  }
}
