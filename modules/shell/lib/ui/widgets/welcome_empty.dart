import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/privacy_line.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Home before anything is paired and with nobody in sight. It is the
/// welcome: what Ferret is for, the one thing to do now, whether it is
/// still looking, and the privacy promise.
///
/// An iPhone can't look for devices on the network, so there it says so
/// plainly: scan the code on the computer.
class WelcomeEmpty extends StatefulWidget {
  const WelcomeEmpty({
    super.key,
    required this.onPairWithCode,
    required this.onCantSee,
    this.patience = const Duration(seconds: 10),
  });

  final VoidCallback onPairWithCode;
  final VoidCallback onCantSee;

  /// How long "Looking…" shows before the way out takes its place, so
  /// nobody stares at a search that never ends.
  final Duration patience;

  @override
  State<WelcomeEmpty> createState() => _WelcomeEmptyState();
}

class _WelcomeEmptyState extends State<WelcomeEmpty> {
  Timer? _patience;
  bool _isLooking = true;

  @override
  void initState() {
    super.initState();
    _patience = Timer(
      widget.patience,
      () => setState(() => _isLooking = false),
    );
  }

  @override
  void dispose() {
    _patience?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lines of text stay readable however wide the view is.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PaneWidths.narrowContent),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final isIphone = defaultTargetPlatform == .iOS;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Spacing.d16,
        Spacing.d32,
        Spacing.d16,
        Spacing.d16,
      ),
      child: Column(
        children: [
          FerretLogo(size: Spacing.d64),
          Spacing.v16,
          Text(
            l10n.welcomeTitle,
            textAlign: .center,
            style: typography.title2.copyWith(color: palette.text),
          ),
          Spacing.v8,
          Text(
            switch (isIphone) {
              true => l10n.emptyBodyIphone,
              false => l10n.emptyBody,
            },
            textAlign: .center,
            style: typography.base1.copyWith(color: palette.mutedText),
          ),
          // "Looking…" and the link that takes its place share a slot as
          // high as the link's target, so nothing moves when they swap.
          Spacing.v12,
          switch (_isLooking) {
            _ when isIphone => SizedBox(height: Spacing.d8),
            true => ConstrainedBox(
              constraints: BoxConstraints(minHeight: TextLink.minHeight),
              child: Center(
                heightFactor: 1,
                child: Text(
                  l10n.nearbyLooking,
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
              ),
            ),
            false => TextLink(
              label: l10n.emptyCantSee,
              onTap: widget.onCantSee,
            ),
          },
          Spacing.v16,
          Button(
            variant: .primary,
            label: switch (isIphone) {
              true => l10n.scanButton,
              false => l10n.pairShowCode,
            },
            mainAxisSize: .min,
            titleExpand: .shrink,
            onPressed: widget.onPairWithCode,
          ),
          Spacing.v24,
          const PrivacyLine(),
          Spacing.v4,
          Text(
            l10n.welcomePlatforms,
            style: typography.caption2.copyWith(color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}
