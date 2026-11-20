import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings → Shelf on a Mac: the ways to reach the shelf in the middle of
/// a drag, what a quick drop on the menubar icon does, and apps whose
/// drags are left alone.
class ShelfReachFrame extends StatefulWidget {
  const ShelfReachFrame({super.key});

  @override
  State<ShelfReachFrame> createState() => _ShelfReachFrameState();
}

class _ShelfReachFrameState extends State<ShelfReachFrame> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<ShelfReachViewModel>().loadApps());
  }

  @override
  Widget build(BuildContext context) {
    final options = context.select<ShelfReachViewModel, ShelfReachOptions>(
      (viewModel) => viewModel.options,
    );
    final springLoading = context.select<ShelfReachViewModel, bool>(
      (viewModel) => viewModel.springLoading,
    );
    final iconDrop = context.select<ShelfReachViewModel, IconDrop>(
      (viewModel) => viewModel.iconDrop,
    );
    final viewModel = context.read<ShelfReachViewModel>();
    final l10n = context.shelfL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.reachTitle),
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.springOpen,
              body: l10n.springOpenBody,
              value: springLoading,
              onChanged: (value) =>
                  unawaited(viewModel.setSpringLoading(value)),
            ),
            GroupedRow(
              title: l10n.iconDropTitle,
              subtitle: l10n.iconDropBody(iconDrop.name),
              trailing: MenuButton(
                icon: LucideIcons.arrowDownToLine,
                tooltip: l10n.iconDropTooltip,
                label: l10n.iconDropShort(iconDrop.name),
                entries: [
                  for (final choice in IconDrop.values)
                    MenuEntry(
                      label: l10n.iconDropChoice(choice.name),
                      onSelected: () =>
                          unawaited(viewModel.setIconDrop(choice)),
                    ),
                ],
              ),
            ),
            SettingSwitchRow(
              title: l10n.shake,
              body: l10n.shakeBody,
              value: options.shake,
              onChanged: (value) => unawaited(viewModel.setShake(value)),
            ),
            if (options.shake)
              GroupedRow(
                title: l10n.sensitivity,
                trailing: MenuButton(
                  icon: LucideIcons.activity,
                  tooltip: l10n.sensitivityTooltip,
                  label: l10n.sensitivityChoice(options.sensitivity.name),
                  entries: [
                    for (final choice in ShakeSensitivity.values)
                      MenuEntry(
                        label: l10n.sensitivityChoice(choice.name),
                        onSelected: () =>
                            unawaited(viewModel.setSensitivity(choice)),
                      ),
                  ],
                ),
              ),
            SettingSwitchRow(
              title: l10n.shiftSummons,
              body: l10n.shiftSummonsBody,
              value: options.shiftSummons,
              onChanged: (value) => unawaited(viewModel.setShiftSummons(value)),
            ),
            SettingSwitchRow(
              title: l10n.boxOnDrag,
              body: l10n.boxOnDragBody,
              value: options.boxOnDrag,
              onChanged: (value) => unawaited(viewModel.setBoxOnDrag(value)),
            ),
            if (options.boxOnDrag)
              GroupedRow(
                title: l10n.boxShows,
                trailing: MenuButton(
                  icon: LucideIcons.panelRight,
                  tooltip: l10n.boxShowsTooltip,
                  label: l10n.boxShowsShort(options.boxShows.name),
                  entries: [
                    for (final choice in ShelfBoxShows.values)
                      MenuEntry(
                        label: l10n.boxShowsChoice(choice.name),
                        onSelected: () =>
                            unawaited(viewModel.setBoxShows(choice)),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (options.watchesDrags) const _IgnoredApps(),
      ],
    );
  }
}

/// Apps whose drags never bring the shelf, and a menu of open apps to add.
class _IgnoredApps extends StatelessWidget {
  const _IgnoredApps();

  @override
  Widget build(BuildContext context) {
    final ignored = context.select<ShelfReachViewModel, List<IgnoredApp>>(
      (viewModel) => viewModel.options.ignoredApps,
    );
    final pickable = context.select<ShelfReachViewModel, List<SystemApp>>(
      (viewModel) => viewModel.pickableApps,
    );
    final viewModel = context.read<ShelfReachViewModel>();
    final l10n = context.shelfL10n;
    final palette = context.palette;
    final note = context.fluffyTheme.typography.caption1.copyWith(
      color: palette.mutedText,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(
          l10n.ignoredTitle,
          trailing: switch (pickable.isEmpty) {
            true => null,
            false => MenuButton(
              icon: LucideIcons.plus,
              tooltip: l10n.ignoredAddTooltip,
              label: l10n.ignoredAdd,
              entries: [
                for (final app in pickable)
                  MenuEntry(
                    label: app.name,
                    onSelected: () => unawaited(viewModel.ignore(app)),
                  ),
              ],
            ),
          },
        ),
        GroupedCard(
          children: [
            if (ignored.isEmpty)
              GroupedCell(child: Text(l10n.ignoredNone, style: note)),
            for (final app in ignored)
              GroupedRow(
                key: ValueKey('ignored.${app.id}'),
                title: app.name,
                trailing: Tappable(
                  tooltip: l10n.ignoredRemove(app.name),
                  semanticLabel: l10n.ignoredRemove(app.name),
                  semanticButton: true,
                  onTap: () => unawaited(viewModel.unignore(app)),
                  child: SizedBox.square(
                    dimension: TextLink.minHeight,
                    child: Icon(
                      LucideIcons.circleMinus,
                      size: Spacing.d16,
                      color: palette.mutedText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
