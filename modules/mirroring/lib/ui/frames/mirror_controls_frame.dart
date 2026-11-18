import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shown device's own buttons under its picture: Back, Home and
/// Recent apps. Nothing for a device that is view only.
class MirrorControlsFrame extends StatelessWidget {
  const MirrorControlsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final hasButtons = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.deviceButtons.isNotEmpty,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    if (!hasButtons) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.d12,
        Spacing.d8,
        Spacing.d12,
        Spacing.d0,
      ),
      child: Wrap(
        alignment: .center,
        spacing: Spacing.d8,
        runSpacing: Spacing.d8,
        children: [
          for (final button in viewModel.deviceButtons)
            Button(
              variant: .ghost,
              label: l10n.buttonName(button),
              onPressed: () => viewModel.press(button),
            ),
        ],
      ),
    );
  }
}
