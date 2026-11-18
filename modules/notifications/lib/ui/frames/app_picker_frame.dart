import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The app list with search, messaging apps first.
class AppPickerFrame extends StatelessWidget {
  const AppPickerFrame({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final state = context.select<AppPickerViewModel, AppPickerState>(
      (viewModel) => viewModel.state,
    );
    final saveFailed = context.select<AppPickerViewModel, bool>(
      (viewModel) => viewModel.saveFailed,
    );
    final messaging = context.select<AppPickerViewModel, List<AppEntry>>(
      (viewModel) => viewModel.messagingApps,
    );
    final others = context.select<AppPickerViewModel, List<AppEntry>>(
      (viewModel) => viewModel.otherApps,
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
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              StatusLine(
                text: l10n.appPickerFailed(deviceName),
                tone: .warning,
              ),
              Spacing.v12,
              Button(
                variant: .secondary,
                label: l10n.tryAgain,
                onPressed: viewModel.reload,
              ),
            ],
          ),
        ),
      ],
      .ready => [
        InputText(hintText: l10n.appPickerSearch, onChanged: viewModel.search),
        if (saveFailed) ...[
          Spacing.v8,
          StatusLine(
            text: l10n.appPickerSaveFailed(deviceName),
            tone: .warning,
          ),
        ],
        if (messaging.isEmpty && others.isEmpty) ...[
          Spacing.v12,
          Text(l10n.appPickerEmpty, style: message),
        ],
        if (messaging.isNotEmpty) ...[
          SectionTitle(l10n.appPickerMessaging),
          _AppGroup(apps: messaging, viewModel: viewModel),
        ],
        if (others.isNotEmpty) ...[
          SectionTitle(l10n.appPickerOther),
          _AppGroup(apps: others, viewModel: viewModel),
        ],
      ],
    };

    return FerretPage(
      title: l10n.appPickerTitle,
      backLabel: l10n.back,
      children: body,
    );
  }
}

class _AppGroup extends StatelessWidget {
  const _AppGroup({required this.apps, required this.viewModel});

  final List<AppEntry> apps;
  final AppPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.symmetric(
      horizontal: Spacing.d12,
      vertical: Spacing.d6,
    ),
    child: Column(
      children: [
        for (final app in apps)
          AppRow(
            key: ValueKey(app.package),
            app: app,
            onChanged: (allowed) => viewModel.setAllowed(app.package, allowed),
          ),
      ],
    ),
  );
}
