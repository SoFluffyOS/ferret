import 'package:drop/l10n/l10n.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Quick Share's settings: whether phones may be shown this device at all.
class QuickShareSettingsFrame extends StatelessWidget {
  const QuickShareSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final quickShare = context.select<DropViewModel, bool>(
      (model) => model.quickShareEnabled,
    );
    final l10n = context.dropL10n;

    return SurfaceCard(
      child: SettingSwitch(
        title: l10n.settingsQuickShare,
        body: l10n.settingsQuickShareBody,
        value: quickShare,
        onChanged: viewModel.setQuickShareEnabled,
      ),
    );
  }
}
