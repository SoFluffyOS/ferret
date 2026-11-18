import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The phone's home card, only while Messages are on but SMS access is
/// missing. Turning Messages on is offered in the shell's "Do more".
class PhoneCardFrame extends StatelessWidget {
  const PhoneCardFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );
    if (stage != .needsAccess) {
      return const SizedBox.shrink();
    }

    final l10n = context.messagesL10n;

    return FeatureCard(
      icon: LucideIcons.messageSquare,
      title: l10n.title,
      subtitle: l10n.phoneCardNeedsAccess,
      subtitleTone: FeatureTone.danger,
      onTap: onSetUp,
      actions: [Button(variant: .primary, label: l10n.fix, onPressed: onSetUp)],
    );
  }
}
