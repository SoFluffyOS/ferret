import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Messages on the phone: the explainer, SMS access with a re-check when
/// the person comes back, the settings page when Android won't ask again,
/// and the RCS limit.
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
      onResume: () =>
          unawaited(context.read<PhoneSetupViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        switch (stage) {
          .unsupported => const _Unsupported(),
          .off => const _Explainer(),
          .needsAccess => const _NeedsAccess(),
          .ready => const _Ready(),
        },
        if (stage != .unsupported) ...[Spacing.v12, const _RcsNote()],
      ],
    );
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported();

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: StatusLine(text: context.messagesL10n.noTelephony, tone: .info),
  );
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;

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

class _NeedsAccess extends StatelessWidget {
  const _NeedsAccess();

  @override
  Widget build(BuildContext context) {
    final stillOff = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final blocked = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.blocked,
    );
    final openFailed = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final asking = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.asking,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final status = switch (stillOff) {
      true => l10n.accessStillOff,
      false => l10n.accessOff,
    };
    final howTo = switch (blocked) {
      true => l10n.accessBlocked,
      false => l10n.accessHowTo,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: status, tone: .warning),
          Spacing.v4,
          Text(
            howTo,
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
            label: switch (blocked) {
              true => l10n.openAppSettings,
              false => l10n.allowAccess,
            },
            enable: !asking,
            onPressed: viewModel.requestAccess,
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
    final contactsMissing = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.contactsMissing,
    );
    final sendMissing = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.sendMissing,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final l10n = context.messagesL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: l10n.accessOn, tone: .good),
          if (contactsMissing) ...[
            Spacing.v8,
            StatusLine(text: l10n.contactsOff, tone: .info),
          ],
          if (sendMissing) ...[
            Spacing.v8,
            StatusLine(text: l10n.sendOff, tone: .info),
          ],
          if (contactsMissing || sendMissing) ...[
            Spacing.v8,
            Button(
              variant: .secondary,
              label: l10n.allowAccess,
              onPressed: viewModel.requestAccess,
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

class _RcsNote extends StatelessWidget {
  const _RcsNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: Spacing.d4),
    child: Text(
      context.messagesL10n.rcsNote,
      style: context.fluffyTheme.typography.caption1.copyWith(
        color: context.palette.mutedText,
      ),
    ),
  );
}
