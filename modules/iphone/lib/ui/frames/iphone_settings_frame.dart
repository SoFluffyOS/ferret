import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/models/models.dart';
import 'package:iphone/ui/frames/iphone_link_frame.dart';
import 'package:iphone/ui/widgets/widgets.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The iPhone in Settings: what works and what doesn't before anything is
/// turned on, then pairing, picking the iPhone, the link's real state and
/// what to show. Looks again when the app comes back from the system's
/// Bluetooth settings.
class IphoneSettingsFrame extends StatefulWidget {
  const IphoneSettingsFrame({super.key});

  @override
  State<IphoneSettingsFrame> createState() => _IphoneSettingsFrameState();
}

class _IphoneSettingsFrameState extends State<IphoneSettingsFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<IphoneSettingsViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final host = context.select<IphoneSettingsViewModel, IphoneHostKind>(
      (viewModel) => viewModel.host,
    );
    final phase = context.select<IphoneSettingsViewModel, LinkPhase>(
      (viewModel) => viewModel.link.phase,
    );
    final openFailed = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final showNotifications = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.showNotifications,
    );
    final showMedia = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.showMedia,
    );
    final hidePreviews = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.hidePreviews,
    );
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;
    final showsLink = enabled && (phase != .off || openFailed);
    final showsOptions =
        enabled && phase != .unsupported && phase != .notConfigured;

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.settingsEnable,
          body: l10n.settingsEnableBody,
          value: enabled,
          onChanged: (value) => unawaited(viewModel.setEnabled(value)),
        ),
        if (showsLink) const GroupedCell(child: IphoneLinkFrame()),
        if (showsOptions) ...[
          SettingSwitchRow(
            title: l10n.settingsNotifications,
            body: l10n.settingsNotificationsBody,
            value: showNotifications,
            onChanged: (value) =>
                unawaited(viewModel.setShowNotifications(value)),
          ),
          if (showNotifications)
            SettingSwitchRow(
              title: l10n.settingsHidePreviews,
              body: l10n.settingsHidePreviewsBody,
              value: hidePreviews,
              onChanged: (value) => unawaited(viewModel.setHidePreviews(value)),
            ),
          SettingSwitchRow(
            title: l10n.settingsMedia,
            body: l10n.settingsMediaBody,
            value: showMedia,
            onChanged: (value) => unawaited(viewModel.setShowMedia(value)),
          ),
        ],
        GroupedCell(
          child: NoticeBlock(
            title: l10n.worksTitle,
            body: l10n.worksBody,
            isProblem: false,
          ),
        ),
        GroupedCell(
          child: NoticeBlock(
            title: l10n.limitsTitle,
            body: l10n.limitsBody(ThisComputer.here),
            isProblem: false,
          ),
        ),
        if (host == .macos)
          GroupedCell(
            child: NoticeBlock(
              title: l10n.macNoteTitle,
              body: l10n.macNote,
              isProblem: false,
            ),
          ),
      ],
    );
  }
}
