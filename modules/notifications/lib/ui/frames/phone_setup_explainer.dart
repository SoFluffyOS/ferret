import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupExplainer extends StatelessWidget {
  const PhoneSetupExplainer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.notificationsL10n;

    return GroupedCard(
      children: [
        GroupedRow(
          title: l10n.explainer(ThisComputer.handheld),
          subtitle: l10n.explainerDetail,
        ),
        GroupedCell(
          child: Button(
            variant: .primary,
            label: l10n.turnOn,
            onPressed: context.read<MirrorSetupViewModel>().turnOn,
          ),
        ),
      ],
    );
  }
}
