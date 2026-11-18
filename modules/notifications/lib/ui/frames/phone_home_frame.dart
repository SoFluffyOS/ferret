import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on the phone: an invitation to set mirroring up, a fix when
/// access is off, or a quiet status line.
class PhoneHomeFrame extends StatelessWidget {
  const PhoneHomeFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<MirrorSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );
    final checked = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.checked,
    );
    final appCount = context.select<MirrorSetupViewModel, int>(
      (viewModel) => viewModel.allowedAppCount,
    );
    final l10n = context.notificationsL10n;

    final subtitle = switch (stage) {
      .off => l10n.explainer,
      _ => null,
    };
    final children = switch (stage) {
      .needsAccess when checked => [
        StatusLine(text: l10n.phoneHomePaused, tone: .warning),
      ],
      .ready => [StatusLine(text: l10n.phoneHomeOn(appCount), tone: .good)],
      _ => <Widget>[],
    };
    final actions = switch (stage) {
      .off => [
        Button(variant: .primary, label: l10n.setUp, onPressed: onSetUp),
      ],
      .needsAccess when checked => [
        Button(variant: .primary, label: l10n.fix, onPressed: onSetUp),
      ],
      _ => <Widget>[],
    };

    return FeatureCard(
      icon: LucideIcons.bell,
      title: l10n.title,
      subtitle: subtitle,
      onTap: onSetUp,
      actions: actions,
      children: children,
    );
  }
}
