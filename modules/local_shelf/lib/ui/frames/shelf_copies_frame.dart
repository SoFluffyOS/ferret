import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Keep copies on the shelf, and for how long: on the shelf page and in
/// Settings.
class ShelfCopiesFrame extends StatelessWidget {
  const ShelfCopiesFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final keepsCopies = context.select<ShelfViewModel, bool>(
      (viewModel) => viewModel.keepsCopies,
    );
    final copiesFor = context.select<ShelfViewModel, ShelfCopiesFor>(
      (viewModel) => viewModel.copiesFor,
    );
    final viewModel = context.read<ShelfViewModel>();
    final l10n = context.shelfL10n;

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.keepCopies,
          body: switch (keepsCopies) {
            true => l10n.keepCopiesBody(copiesFor.name),
            false => l10n.keepCopiesOffBody,
          },
          value: keepsCopies,
          onChanged: (value) => unawaited(viewModel.setKeepCopies(value)),
        ),
        if (keepsCopies)
          GroupedRow(
            title: l10n.copiesFor,
            trailing: MenuButton(
              icon: LucideIcons.timer,
              tooltip: l10n.copiesForTooltip,
              label: l10n.copiesForShort(copiesFor.name),
              entries: [
                for (final choice in ShelfCopiesFor.values)
                  MenuEntry(
                    label: l10n.copiesForChoice(choice.name),
                    onSelected: () => unawaited(viewModel.setCopiesFor(choice)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
