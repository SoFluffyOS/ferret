import 'dart:async';
import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:transport/transport.dart';
import 'package:url_launcher/url_launcher.dart';

/// Devices near you: unpaired Ferret devices on this network, each with a
/// Pair button, kept up to date while the screen is open. Once something
/// is paired, what features found near (a phone on a cable) is listed with
/// them.
class NearbyFrame extends StatefulWidget {
  const NearbyFrame({
    super.key,
    this.watch = true,
    this.onPairWithCode,
    this.onCantSee,
  });

  /// With this, the frame is Home before anything is paired: it welcomes,
  /// and offers the code when no device, or not the right one, is in sight.
  final VoidCallback? onPairWithCode;

  /// Where "Can't see it?" leads once looking found nobody.
  final VoidCallback? onCantSee;

  /// Whether the user is waiting for a device to show up here. Then Ferret
  /// keeps looking and says so, and says when it found nothing. Otherwise
  /// the section only appears when there is someone to pair with.
  final bool watch;

  @override
  State<NearbyFrame> createState() => _NearbyFrameState();
}

class _NearbyFrameState extends State<NearbyFrame> {
  late final NearbyViewModel _viewModel = NearbyViewModel(
    ShellScope.read(context).featureContext.engine,
    watch: widget.watch,
  );

  @override
  void didUpdateWidget(NearbyFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.watch && !oldWidget.watch) {
      unawaited(_viewModel.lookAgain());
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final welcomes = widget.onPairWithCode != null;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: FeatureChangesListener(
        features: scope.features,
        builder: (context) => _Nearby(
          watch: widget.watch,
          onPairWithCode: widget.onPairWithCode,
          onCantSee: widget.onCantSee,
          rows: [
            if (!welcomes)
              for (final feature in scope.features)
                ...feature.nearbyRows(context, scope.featureContext),
          ],
        ),
      ),
    );
  }
}

class _Nearby extends StatelessWidget {
  const _Nearby({
    required this.watch,
    required this.onPairWithCode,
    required this.onCantSee,
    required this.rows,
  });

  final bool watch;
  final VoidCallback? onPairWithCode;
  final VoidCallback? onCantSee;

  /// What features found near that isn't a device to pair with.
  final List<FeatureNearbyRow> rows;

  @override
  Widget build(BuildContext context) {
    final peers = context.select<NearbyViewModel, List<DiscoveredPeer>>(
      (viewModel) => viewModel.peers,
    );
    final attempt = context.select<NearbyViewModel, NearbyAttempt?>(
      (viewModel) => viewModel.attempt,
    );
    final isLooking = context.select<NearbyViewModel, bool>(
      (viewModel) => viewModel.isLooking,
    );
    final hasLooked = context.select<NearbyViewModel, bool>(
      (viewModel) => viewModel.hasLooked,
    );
    final isBlocked = context.select<NearbyViewModel, bool>(
      (viewModel) => viewModel.isBlocked,
    );
    final viewModel = context.read<NearbyViewModel>();
    final l10n = context.shellL10n;

    final waitsForPeers = watch || isBlocked;
    if (peers.isEmpty && rows.isEmpty && !waitsForPeers) {
      return const SizedBox.shrink();
    }

    // An iPhone finds others only through Bonjour, and only while Ferret
    // is open on both, so "Looking…" or "allow Local Network" would
    // mislead on an empty list: it offers scanning the computer's code.
    final isIphone = defaultTargetPlatform == .iOS;
    final onPairWithCode = this.onPairWithCode;
    if (peers.isEmpty && rows.isEmpty && isIphone && onPairWithCode == null) {
      return const SizedBox.shrink();
    }

    if (peers.isEmpty && (!isBlocked || isIphone) && onPairWithCode != null) {
      return WelcomeEmpty(
        onPairWithCode: onPairWithCode,
        onCantSee: onCantSee ?? onPairWithCode,
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (onPairWithCode != null && peers.isNotEmpty) const WelcomeIntro(),
        SectionTitle(
          l10n.homeNearby,
          trailing: switch (isLooking && peers.isNotEmpty) {
            true => _Looking(l10n.nearbyLooking),
            false => null,
          },
        ),
        for (final (index, peer) in peers.indexed)
          NearbyTile(
            key: ValueKey(peer.deviceId),
            peer: peer,
            attempt: switch (attempt) {
              final attempt? when attempt.peer.deviceId == peer.deviceId =>
                attempt,
              _ => null,
            },
            isFirst: index == 0 && attempt == null,
            onPair: () => unawaited(viewModel.pair(peer)),
            onConfirm: viewModel.confirm,
            onCancel: viewModel.cancel,
            onDismiss: viewModel.dismiss,
          ),
        for (final row in rows)
          NearbyFeatureTile(key: ValueKey(row.id), row: row),
        if (peers.isEmpty && waitsForPeers)
          switch ((isBlocked, hasLooked && !isLooking)) {
            (true, _) => NearbyNotice(
              title: l10n.nearbyBlockedTitle,
              body: l10n.nearbyBlockedBody,
              actionLabel: l10n.nearbyOpenSettings,
              onAction: _openLocalNetworkSettings,
            ),
            (_, true) => NearbyNotice(
              body: l10n.nearbyNone,
              actionLabel: l10n.nearbyLookAgain,
              onAction: () => unawaited(viewModel.lookAgain()),
            ),
            _ => NearbyNotice(body: l10n.nearbyLooking),
          },
        if (onPairWithCode != null && peers.isNotEmpty)
          WelcomeNearby(onPairWithCode: onPairWithCode),
      ],
    );
  }

  /// macOS and iOS keep the switch in System Settings; elsewhere there is
  /// nothing to open.
  void _openLocalNetworkSettings() {
    final target = switch (Platform.isMacOS) {
      true =>
        'x-apple.systempreferences:com.apple.preference.security'
            '?Privacy_LocalNetwork',
      false => 'app-settings:',
    };
    unawaited(launchUrl(Uri.parse(target)));
  }
}

class _Looking extends StatelessWidget {
  const _Looking(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.fluffyTheme.typography.caption1.copyWith(
        color: context.palette.mutedText,
      ),
    );
  }
}
