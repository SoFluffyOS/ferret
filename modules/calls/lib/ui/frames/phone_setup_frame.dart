import 'dart:async';

import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Calls settings on the phone: the explainer, the permissions with a
/// re-check on return, and what computers can do once it is on.
class PhoneSetupFrame extends StatefulWidget {
  const PhoneSetupFrame({super.key});

  @override
  State<PhoneSetupFrame> createState() => _PhoneSetupFrameState();
}

class _PhoneSetupFrameState extends State<PhoneSetupFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<PhoneSetupViewModel>().refresh()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, CallsSetupStage>(
      (viewModel) => viewModel.stage,
    );

    return switch (stage) {
      .off => const _Explainer(),
      .needsPermission => const _NeedsPermission(),
      .ready => const _Ready(),
    };
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            l10n.explainer,
            style: typography.base1.copyWith(color: palette.text),
          ),
          Spacing.v4,
          Text(
            l10n.explainerDetail,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          Spacing.v12,
          Button(
            variant: .primary,
            label: l10n.turnOn,
            onPressed: context.read<PhoneSetupViewModel>().turnOn,
          ),
        ],
      ),
    );
  }
}

class _NeedsPermission extends StatelessWidget {
  const _NeedsPermission();

  @override
  Widget build(BuildContext context) {
    final stillOff = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final needsSettings = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.needsSettings,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final status = switch (stillOff && needsSettings) {
      true => l10n.permissionStillOff,
      false => l10n.permissionOff,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: status, tone: .warning),
          Spacing.v4,
          Text(
            switch (needsSettings) {
              true => l10n.permissionHowToSettings,
              false => l10n.permissionHowTo,
            },
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          const _OpenFailed(),
          Spacing.v12,
          Button(
            variant: .primary,
            label: switch (needsSettings) {
              true => l10n.openSettings,
              false => l10n.allow,
            },
            onPressed: viewModel.allow,
          ),
          Spacing.v8,
          Button(
            variant: .ghost,
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ],
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready();

  @override
  Widget build(BuildContext context) {
    final abilities = context
        .select<PhoneSetupViewModel, (bool, bool, bool, bool)>(
          (viewModel) => (
            viewModel.canSeeNumbers,
            viewModel.canSeeContacts,
            viewModel.canAnswer,
            viewModel.canDial,
          ),
        );
    final hasMissing = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.hasMissing,
    );
    final needsSettings = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.needsSettings,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final (canSeeNumbers, canSeeContacts, canAnswer, canDial) = abilities;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: l10n.ready, tone: .good),
          Spacing.v8,
          _Ability(text: l10n.capNumbers, allowed: canSeeNumbers),
          _Ability(text: l10n.capContacts, allowed: canSeeContacts),
          _Ability(text: l10n.capAnswer, allowed: canAnswer),
          _Ability(text: l10n.capDial, allowed: canDial),
          Spacing.v8,
          Text(
            l10n.audioOnPhone,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          const _OpenFailed(),
          if (hasMissing) ...[
            Spacing.v12,
            Button(
              variant: .ghost,
              label: switch (needsSettings) {
                true => l10n.openSettings,
                false => l10n.allowRest,
              },
              onPressed: viewModel.allow,
            ),
          ],
          Spacing.v8,
          Button(
            variant: .ghost,
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ],
      ),
    );
  }
}

class _Ability extends StatelessWidget {
  const _Ability({required this.text, required this.allowed});

  final String text;
  final bool allowed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Spacing.d4),
    child: StatusLine(
      text: text,
      tone: switch (allowed) {
        true => .good,
        false => .neutral,
      },
    ),
  );
}

class _OpenFailed extends StatelessWidget {
  const _OpenFailed();

  @override
  Widget build(BuildContext context) {
    final openFailed = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    if (!openFailed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: Text(
        context.callsL10n.openSettingsFailed,
        style: context.fluffyTheme.typography.caption1.copyWith(
          color: context.palette.danger,
        ),
      ),
    );
  }
}
