import 'package:calls/l10n/l10n.dart';
import 'package:calls/models/models.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/calls.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The dialer for one phone: its call going on, a number field, a Call
/// button, and the phone's recent calls to pick a number from. With room,
/// the recent calls sit next to the dialer.
class DialerFrame extends StatefulWidget {
  const DialerFrame({super.key, this.ongoing});

  /// The phone's ringing or ongoing calls, above the dialer.
  final Widget? ongoing;

  @override
  State<DialerFrame> createState() => _DialerFrameState();
}

class _DialerFrameState extends State<DialerFrame> {
  final TextEditingController _number = .new();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _call() => context.read<DialerViewModel>().call(_number.text);

  void _pick(CallLogEntry entry) {
    _number.text = entry.number;
  }

  @override
  Widget build(BuildContext context) {
    final calling = context.select<DialerViewModel, bool>(
      (viewModel) => viewModel.calling,
    );
    final outcome = context.select<DialerViewModel, CommandOutcome?>(
      (viewModel) => viewModel.outcome,
    );
    final deviceName = context.read<DialerViewModel>().deviceName;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final invalidNumber = outcome == CommandOutcome.invalidNumber;

    return TwoColumns(
      leading: [
        ?widget.ongoing,
        SectionTitle(l10n.dialSection),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              InputText(
                controller: _number,
                label: l10n.numberLabel,
                hintText: l10n.numberHint,
                keyboardType: .phone,
                errorText: switch (invalidNumber) {
                  true => l10n.outcomeInvalidNumber,
                  false => null,
                },
                onSubmitted: (_) => _call(),
              ),
              Spacing.v12,
              Button(
                variant: .primary,
                label: l10n.call,
                icon: Icon(LucideIcons.phone, size: Spacing.d16),
                enable: !calling,
                onPressed: _call,
              ),
              Spacing.v8,
              Text(
                _statusText(l10n, outcome, deviceName),
                style: typography.caption1.copyWith(
                  color: switch (outcome) {
                    null || .ok || .invalidNumber => palette.mutedText,
                    _ => palette.danger,
                  },
                ),
              ),
            ],
          ),
        ),
      ],
      trailing: [
        SectionTitle(l10n.recentCalls),
        _RecentCalls(onPick: _pick),
      ],
    );
  }

  String _statusText(
    CallsLocalizations l10n,
    CommandOutcome? outcome,
    String deviceName,
  ) => switch (outcome) {
    null || .invalidNumber => l10n.audioStays(deviceName),
    .ok => l10n.callStarted(deviceName),
    final problem => l10n.outcomeText(problem, deviceName),
  };
}

class _RecentCalls extends StatelessWidget {
  const _RecentCalls({required this.onPick});

  final void Function(CallLogEntry entry) onPick;

  @override
  Widget build(BuildContext context) {
    final entries = context.select<DialerViewModel, List<CallLogEntry>>(
      (viewModel) => viewModel.entries,
    );
    final loading = context.select<DialerViewModel, bool>(
      (viewModel) => viewModel.loading,
    );
    final problem = context.select<DialerViewModel, CallLogProblem?>(
      (viewModel) => viewModel.logProblem,
    );
    final viewModel = context.read<DialerViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final muted = typography.body2.copyWith(color: palette.mutedText);

    if (problem != null) {
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              l10n.logProblemText(problem, viewModel.deviceName),
              style: typography.body2.copyWith(color: palette.text),
            ),
            Spacing.v12,
            GhostButton(
              label: l10n.retry,
              enable: !loading,
              onPressed: viewModel.loadRecent,
            ),
          ],
        ),
      );
    }

    if (entries.isEmpty) {
      return SurfaceCard(
        child: Text(
          switch (loading) {
            true => l10n.recentLoading,
            false => l10n.recentEmpty,
          },
          style: muted,
        ),
      );
    }

    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d4,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          for (final entry in entries)
            CallLogRow(
              key: ValueKey(entry.id),
              entry: entry,
              onTap: switch (entry.number.isEmpty) {
                true => null,
                false => () => onPick(entry),
              },
            ),
        ],
      ),
    );
  }
}
