import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// On Android 17, once Ferret targets it: why Ferret needs the local
/// network, before Android asks, with Allow. Turned down for good, it
/// says where in Settings to allow it. Nothing anywhere else.
class LocalNetworkCard extends StatefulWidget {
  const LocalNetworkCard({super.key, this.system});

  /// Where the card reads what Android allows. Left out, this phone.
  final FerretSystem? system;

  @override
  State<LocalNetworkCard> createState() => _LocalNetworkCardState();
}

class _LocalNetworkCardState extends State<LocalNetworkCard>
    with WidgetsBindingObserver {
  late final LocalNetworkViewModel _viewModel = .new(system: widget.system);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_viewModel.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) {
      unawaited(_viewModel.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _Ask(),
    );
  }
}

class _Ask extends StatelessWidget {
  const _Ask();

  @override
  Widget build(BuildContext context) {
    final (:asks, :isBlocked) = context.select(
      (LocalNetworkViewModel viewModel) =>
          (asks: viewModel.asks, isBlocked: viewModel.isBlocked),
    );
    if (!asks) {
      return const SizedBox.shrink();
    }

    final viewModel = context.read<LocalNetworkViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.wifi,
                  size: Spacing.d20,
                  color: palette.accent,
                ),
                Spacing.h8,
                Expanded(
                  child: Text(
                    l10n.localNetworkTitle,
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                ),
              ],
            ),
            Spacing.v6,
            Text(
              l10n.localNetworkBody,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            Spacing.v12,
            Row(
              children: [
                Expanded(
                  child: switch (isBlocked) {
                    true => Text(
                      l10n.localNetworkBlocked,
                      style: typography.base2.copyWith(color: palette.text),
                    ),
                    false => const SizedBox.shrink(),
                  },
                ),
                Spacing.h12,
                switch (isBlocked) {
                  true => RowActionButton(
                    label: l10n.localNetworkOpenSettings,
                    tooltip: l10n.localNetworkOpenSettingsTooltip,
                    onPressed: () => unawaited(viewModel.allow()),
                  ),
                  false => RowActionButton(
                    label: l10n.localNetworkAllow,
                    tooltip: l10n.localNetworkAllowTooltip,
                    onPressed: () => unawaited(viewModel.allow()),
                  ),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }
}
