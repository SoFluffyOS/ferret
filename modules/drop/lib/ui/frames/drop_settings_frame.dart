import 'package:drop/l10n/l10n.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Files' settings: where files go, and whether your own devices have to
/// ask first. LocalSend and Quick Share have their own parts.
class DropSettingsFrame extends StatelessWidget {
  const DropSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final folder = context.select<DropViewModel, String>(
      (model) => model.receiveFolder,
    );
    final folderLabel = context.select<DropViewModel, String>(
      (model) => model.receiveFolderText(context.dropL10n),
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
    final titleStyle = GroupedRow.titleStyleOf(context);

    return GroupedCard(
      children: [
        // Not a GroupedRow: the folder line carries the full path as its
        // tooltip, which a row's subtitle can't.
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: GroupedRow.minHeight),
          child: Padding(
            // On a touch screen Change… sits in the card's corner: as far
            // from its top as from its side, like every button there.
            padding: EdgeInsets.symmetric(
              horizontal: PageInsets.row,
              vertical: switch ((viewModel.canChangeFolder, _touch)) {
                (true, true) => PageInsets.row,
                _ => Spacing.d8,
              },
            ),
            child: Row(
              children: [
                Expanded(
                  // "Receive folder, Download › Ferret" as one stop; the
                  // full path is only the pointer's tooltip.
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          l10n.settingsReceiveFolder,
                          style: titleStyle.copyWith(color: palette.text),
                        ),
                        Spacing.vertical(Spacing.d2),
                        Semantics(
                          label: folderLabel,
                          excludeSemantics: true,
                          child: Tappable(
                            tooltip: folder,
                            child: Text(
                              folderLabel,
                              style: typography.caption1.copyWith(
                                color: palette.mutedText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (viewModel.canChangeFolder) ...[
                  Spacing.h8,
                  GhostButton(
                    mainAxisSize: .min,
                    label: l10n.settingsChange,
                    onPressed: () => _changeFolder(context, viewModel),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (customFolder)
          GroupedCell(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GhostButton(
                mainAxisSize: .min,
                label: l10n.settingsUseDefault,
                onPressed: viewModel.resetReceiveFolder,
              ),
            ),
          ),
        SettingSwitchRow(
          title: l10n.settingsAutoAccept,
          body: l10n.settingsAutoAcceptBody,
          value: autoAccept,
          onChanged: viewModel.setAutoAccept,
        ),
      ],
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
    final name = await FerretTextDialog.show(
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

bool get _touch => switch (defaultTargetPlatform) {
  .android || .iOS || .fuchsia => true,
  .macOS || .windows || .linux => false,
};
