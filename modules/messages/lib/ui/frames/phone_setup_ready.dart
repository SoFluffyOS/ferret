import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupReady extends StatelessWidget {
  const PhoneSetupReady({super.key});

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
              variant: .ghost,
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
