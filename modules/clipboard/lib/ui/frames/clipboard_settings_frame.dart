import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:clipboard/view_models/clipboard_view_model.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The clipboard section in Settings.
class ClipboardSettingsFrame extends StatelessWidget {
  const ClipboardSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final autoSend = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.autoSend,
    );
    final autoReceive = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.autoReceive,
    );
    final syncImages = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.syncImages,
    );
    final syncSensitive = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.syncSensitive,
    );
    final needsManualSend = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.needsManualSend,
    );
    final access = context.select<ClipboardViewModel, ClipboardAccess>(
      (viewModel) => viewModel.access,
    );
    final canSendInBackground = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.canSendInBackground,
    );
    final backgroundSend = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.backgroundSend,
    );
    final megabytes = context.select<ClipboardViewModel, int>(
      (viewModel) => viewModel.maxImageMegabytes,
    );
    final minutes = context.select<ClipboardViewModel, int>(
      (viewModel) => viewModel.expiryMinutes,
    );
    final historyCount = context.select<ClipboardViewModel, int>(
      (viewModel) => viewModel.historyCount,
    );
    final viewModel = context.read<ClipboardViewModel>();
    final l10n = context.clipboardL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (needsManualSend)
            SettingInfoRow(
              title: l10n.settingsWhyManual,
              body: switch (access) {
                .onRequest => l10n.settingsWhyManualIos,
                .whileFocused => l10n.settingsWhyManualWayland,
                _ => l10n.settingsWhyManualAndroid,
              },
              showLock: false,
            ),
          SettingSwitchRow(
            title: l10n.settingsAutoSend,
            body: switch ((needsManualSend, access)) {
              (true, .whileFocused) => l10n.settingsAutoSendBodyWayland,
              (true, _) => l10n.settingsAutoSendBodyManual,
              (false, _) => l10n.settingsAutoSendBody,
            },
            value: autoSend,
            onChanged: viewModel.setAutoSend,
          ),
          if (access == .foreground && canSendInBackground)
            SettingSwitchRow(
              title: l10n.settingsBackgroundSend,
              body: l10n.settingsBackgroundSendBody,
              value: backgroundSend,
              onChanged: viewModel.setBackgroundSend,
            ),
          if (access == .foreground && !canSendInBackground)
            SettingInfoRow(
              title: l10n.settingsBackgroundSend,
              body: switch (backgroundSend) {
                true => l10n.settingsBackgroundSendLost,
                false => l10n.settingsBackgroundSendLocked,
              },
            ),
          SettingSwitchRow(
            title: l10n.settingsAutoReceive,
            body: l10n.settingsAutoReceiveBody,
            value: autoReceive,
            onChanged: viewModel.setAutoReceive,
          ),
          SettingSwitchRow(
            title: l10n.settingsImages,
            body: l10n.settingsImagesBody(megabytes),
            value: syncImages,
            onChanged: viewModel.setSyncImages,
          ),
          SettingSwitchRow(
            title: l10n.settingsSensitive,
            body: l10n.settingsSensitiveBody(minutes),
            value: syncSensitive,
            onChanged: viewModel.setSyncSensitive,
          ),
          Spacing.v8,
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.settingsHistory(historyCount),
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
              ),
              Spacing.h12,
              Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.settingsClearHistory,
                enable: historyCount > 0,
                onPressed: viewModel.clearHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
