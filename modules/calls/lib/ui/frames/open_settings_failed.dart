import 'package:calls/l10n/l10n.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class OpenSettingsFailed extends StatelessWidget {
  const OpenSettingsFailed({super.key});

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
