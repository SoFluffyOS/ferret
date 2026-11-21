import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Asks whether to pair with a device that shows the same six digits, for
/// as long as that device waits.
class PairingPromptDialog extends StatefulWidget {
  const PairingPromptDialog({super.key, required this.prompt});

  final PairingPrompt prompt;

  static Future<void> show(BuildContext context, PairingPrompt prompt) async {
    final accepted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99000000),
      pageBuilder: (_, _, _) => PairingPromptDialog(prompt: prompt),
    );

    switch (accepted) {
      case true:
        prompt.accept();
      case _:
        prompt.reject();
    }
  }

  @override
  State<PairingPromptDialog> createState() => _PairingPromptDialogState();
}

class _PairingPromptDialogState extends State<PairingPromptDialog> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = .periodic(const Duration(seconds: 1), (_) => setState(() {}));
    // The request can end without an answer here: it times out, or the
    // other device gives up. Take this dialog away, and only this one, once
    // the navigator is free.
    unawaited(widget.prompt.decision.then((_) => _closeSelf()));
  }

  void _closeSelf() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route != null && route.isActive) {
        Navigator.of(context).removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  int get _secondsLeft {
    final left = widget.prompt.expiresAt.difference(DateTime.now());
    return ((left.inMilliseconds + 999) ~/ 1000).clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    // Esc is "Not now": the barrier can't be dismissed, so the route
    // doesn't answer it by itself. The keys only get here while something
    // inside has the focus, which the route's own scope doesn't count as.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(false),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          child: _card(context),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final prompt = widget.prompt;
    final name = prompt.device.name;
    final also = _alsoLine(l10n, prompt.alsoDevices);

    // Scrolls when it is taller than the view, as it is in the popover
    // with text set large: the answers are at the bottom.
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Spacing.d16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Spacing.d320),
          child: DialogShape(
            child: Column(
              mainAxisSize: .min,
              children: [
                Icon(
                  deviceIconFor(
                    prompt.device.formFactor,
                    prompt.device.platform,
                  ),
                  size: Spacing.d32,
                  color: palette.text,
                ),
                Spacing.v8,
                Text(
                  l10n.promptTitle(name),
                  textAlign: .center,
                  style: typography.title3.copyWith(color: palette.text),
                ),
                Spacing.v16,
                ComparisonCode(code: prompt.code),
                Spacing.v12,
                Text(
                  l10n.promptBody(name),
                  textAlign: .center,
                  style: typography.body2.copyWith(color: palette.mutedText),
                ),
                if (also case final also?) ...[
                  Spacing.v8,
                  Text(
                    also,
                    textAlign: .center,
                    style: typography.base2.copyWith(color: palette.mutedText),
                  ),
                ],
                Spacing.vertical(Spacing.d20),
                ActionPair(
                  ghostLabel: l10n.promptReject,
                  onGhost: () => Navigator.of(context).pop(false),
                  primaryLabel: l10n.promptAccept,
                  onPrimary: () => Navigator.of(context).pop(true),
                ),
                Spacing.v8,
                Text(
                  l10n.promptSecondsLeft(_secondsLeft),
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// At most two names, then a count, so the line stays one line.
  String? _alsoLine(ShellLocalizations l10n, List<String> names) =>
      switch (names) {
        [] => null,
        [final first] => l10n.promptAlsoOne(first),
        [final first, final second] => l10n.promptAlsoTwo(first, second),
        [final first, final second, ...final rest] => l10n.promptAlsoMore(
          first,
          second,
          rest.length,
        ),
      };
}
