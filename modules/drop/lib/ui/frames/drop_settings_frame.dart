import 'package:drop/l10n/l10n.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Drop's settings: where files go, and whether to ask first.
class DropSettingsFrame extends StatelessWidget {
  const DropSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final folder = context.select<DropViewModel, String>(
      (model) => model.receiveFolder,
    );
    final autoAccept = context.select<DropViewModel, bool>(
      (model) => model.autoAccept,
    );
    final customFolder = context.select<DropViewModel, bool>(
      (model) => model.hasCustomFolder,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.dropL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.settingsReceiveFolder,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                    Spacing.vertical(Spacing.d2),
                    Text(
                      folder,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (viewModel.canChangeFolder)
                Button(
                  variant: .secondary,
                  label: l10n.settingsChange,
                  onPressed: () => _changeFolder(context, viewModel),
                ),
            ],
          ),
          if (customFolder)
            Align(
              alignment: .centerLeft,
              child: Button(
                variant: .ghost,
                label: l10n.settingsUseDefault,
                onPressed: viewModel.resetReceiveFolder,
              ),
            ),
          Spacing.v16,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.settingsAutoAccept,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                    Spacing.vertical(Spacing.d2),
                    Text(
                      l10n.settingsAutoAcceptBody,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              SwitchToggle(
                value: autoAccept,
                onChanged: viewModel.setAutoAccept,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeFolder(
    BuildContext context,
    DropViewModel viewModel,
  ) async {
    if (!viewModel.usesFolderName) {
      await viewModel.pickReceiveFolder();
      return;
    }

    final l10n = context.dropL10n;
    final name = await InputTextDialog.show(
      context,
      title: l10n.settingsReceiveFolder,
      labelText: l10n.settingsFolderName,
      cancelText: l10n.actionCancel,
      confirmText: l10n.settingsSave,
      initialValue: viewModel.folderName,
    );
    if (name == null) {
      return;
    }

    await viewModel.setFolderName(name);
  }
}
