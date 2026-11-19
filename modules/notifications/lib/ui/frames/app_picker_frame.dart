import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// All apps first; muting a few or picking only a few is one tap away, with
/// the app list, its search and select all or none.
class AppPickerFrame extends StatelessWidget {
  const AppPickerFrame({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final state = context.select<AppPickerViewModel, AppPickerState>(
      (viewModel) => viewModel.state,
    );
    final viewModel = context.read<AppPickerViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final message = typography.body2.copyWith(color: palette.mutedText);

    final body = switch (state) {
      .loading => [
        SurfaceCard(child: Text(l10n.appPickerLoading, style: message)),
      ],
      .failed => [
        GroupedCard(
          children: [
            GroupedCell(
              child: StatusLine(
                text: l10n.appPickerFailed(deviceName),
                tone: .warning,
              ),
            ),
            GroupedCell(
              child: Button(
                variant: .ghost,
                label: l10n.tryAgain,
                onPressed: viewModel.reload,
              ),
            ),
          ],
        ),
      ],
      .ready => [
        const _FilterCard(),
        _AppList(deviceName: deviceName),
      ],
    };

    return FerretPage(
      title: l10n.appPickerTitle,
      backLabel: l10n.back,
      children: body,
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard();

  @override
  Widget build(BuildContext context) {
    final filter = context.select<AppPickerViewModel, AppFilter>(
      (viewModel) => viewModel.filter,
    );
    final viewModel = context.read<AppPickerViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;

    return GroupedCard(
      children: [
        FilterOptionRow(
          filter: .APP_FILTER_ALL,
          selected: filter,
          title: l10n.filterAll,
          detail: l10n.filterAllDetail,
          onSelected: viewModel.setFilter,
        ),
        FilterOptionRow(
          filter: .APP_FILTER_ALL_EXCEPT,
          selected: filter,
          title: l10n.filterAllExcept,
          detail: l10n.filterAllExceptDetail,
          onSelected: viewModel.setFilter,
        ),
        FilterOptionRow(
          filter: .APP_FILTER_ONLY,
          selected: filter,
          title: l10n.filterOnly,
          detail: l10n.filterOnlyDetail,
          onSelected: viewModel.setFilter,
        ),
        GroupedCell(
          child: Text(
            l10n.filterBuiltIn,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ),
      ],
    );
  }
}

class _AppList extends StatelessWidget {
  const _AppList({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final filter = context.select<AppPickerViewModel, AppFilter>(
      (viewModel) => viewModel.filter,
    );
    final saveFailed = context.select<AppPickerViewModel, bool>(
      (viewModel) => viewModel.saveFailed,
    );
    final apps = context.select<AppPickerViewModel, List<PickerApp>>(
      (viewModel) => viewModel.apps,
    );
    final viewModel = context.read<AppPickerViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final hint = switch (filter) {
      .APP_FILTER_ALL_EXCEPT => l10n.appPickerMuteHint,
      .APP_FILTER_ONLY => l10n.appPickerOnlyHint,
      _ => null,
    };

    final inset = EdgeInsets.symmetric(horizontal: PageInsets.row);
    final saveNotice = Padding(
      padding: inset.copyWith(top: Spacing.d8),
      child: StatusLine(
        text: l10n.appPickerSaveFailed(deviceName),
        tone: .warning,
      ),
    );

    if (hint == null) {
      return Column(
        crossAxisAlignment: .stretch,
        children: [if (saveFailed) saveNotice],
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.appPickerApps),
        Padding(
          padding: inset,
          child: Text(
            hint,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ),
        Spacing.v8,
        InputText(hintText: l10n.appPickerSearch, onChanged: viewModel.search),
        Spacing.v8,
        Wrap(
          spacing: Spacing.d8,
          runSpacing: Spacing.d8,
          children: [
            Button(
              variant: .ghost,
              mainAxisSize: .min,
              label: l10n.selectAll,
              onPressed: () => viewModel.setAllShown(true),
            ),
            Button(
              variant: .ghost,
              mainAxisSize: .min,
              label: l10n.selectNone,
              onPressed: () => viewModel.setAllShown(false),
            ),
          ],
        ),
        if (saveFailed) saveNotice,
        Spacing.v12,
        if (apps.isEmpty)
          Padding(
            padding: inset,
            child: Text(
              l10n.appPickerEmpty,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
          ),
        if (apps.isNotEmpty)
          GroupedCard(
            separatorIndent: PageInsets.row + AppRow.iconSize + Spacing.d12,
            children: [
              for (final (:app, :forwards) in apps)
                AppRow(
                  key: ValueKey(app.package),
                  app: app,
                  value: forwards,
                  onChanged: (allowed) =>
                      viewModel.setAllowed(app.package, allowed),
                ),
            ],
          ),
      ],
    );
  }
}
