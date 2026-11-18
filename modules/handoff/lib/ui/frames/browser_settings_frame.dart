import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/widgets/widgets.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The browser extension's settings: the switch, whether the bridge is up
/// (with a retry when it couldn't start), and the browsers allowed.
class BrowserSettingsFrame extends StatelessWidget {
  const BrowserSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.handoffL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final viewModel = context.read<HandoffViewModel>();
    final enabled = context.select<HandoffViewModel, bool>(
      (viewModel) => viewModel.browserBridgeEnabled,
    );
    final state = context.select<HandoffViewModel, BrowserBridgeState>(
      (viewModel) => viewModel.browserBridgeState,
    );
    final clients = context.select<HandoffViewModel, List<BrowserClient>>(
      (viewModel) => viewModel.browserClients,
    );
    final connected = context.select<HandoffViewModel, Set<String>>(
      (viewModel) => viewModel.connectedBrowserIds,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SettingSwitchRow(
            title: l10n.settingsBrowserBridge,
            body: l10n.settingsBrowserBridgeBody,
            value: enabled,
            onChanged: viewModel.setBrowserBridgeEnabled,
          ),
          if (state.status == .failed) ...[
            Spacing.v8,
            Text(
              l10n.browserBridgeFailed,
              style: typography.caption1.copyWith(
                color: switch (clients.isEmpty) {
                  true => palette.mutedText,
                  false => palette.warning,
                },
              ),
            ),
            Spacing.v8,
            Align(
              alignment: .centerLeft,
              child: Button(
                variant: .ghost,
                label: l10n.browserBridgeRetry,
                mainAxisSize: .min,
                onPressed: () => unawaited(viewModel.retryBrowserBridge()),
              ),
            ),
          ],
          if (state.status == .listening) ...[
            Spacing.v8,
            Text(
              switch (clients.isEmpty) {
                true => l10n.browserClientsEmpty,
                false => l10n.browserBridgeListening,
              },
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            for (final client in clients)
              BrowserClientRow(
                key: ValueKey(client.id),
                name: client.name,
                isConnected: connected.contains(client.id),
                onRemove: () => unawaited(viewModel.removeBrowser(client)),
              ),
          ],
        ],
      ),
    );
  }
}
