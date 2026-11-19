import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/dialogs/dialogs.dart';

/// Shows a pairing request as soon as one arrives, wherever the app is.
class PairingPromptListener extends StatefulWidget {
  const PairingPromptListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<PairingPromptListener> createState() => _PairingPromptListenerState();
}

class _PairingPromptListenerState extends State<PairingPromptListener> {
  PairingPrompt? _showing;

  @override
  Widget build(BuildContext context) {
    final prompt = context.select<EngineHost, PairingPrompt?>(
      (host) => host.pendingPrompt,
    );
    if (prompt != null && prompt != _showing) {
      _showing = prompt;
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(prompt));
    }

    return widget.child;
  }

  /// Brings the request in front of the user wherever they are: the
  /// popover opens on a Mac, a notification shows when the app is behind.
  Future<void> _show(PairingPrompt prompt) async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    final featureContext = ShellScope.read(context).featureContext;
    final l10n = navigatorContext.shellL10n;
    final noticeId = 'shell.pair.${prompt.device.id}';
    unawaited(featureContext.reveal());
    unawaited(
      featureContext.notifier.show(
        LocalNotice(
          id: noticeId,
          channel: .incoming,
          title: l10n.promptNotice(prompt.device.name),
          body: l10n.promptNoticeBody,
        ),
      ),
    );

    await PairingPromptDialog.show(navigatorContext, prompt);
    unawaited(featureContext.notifier.cancel(noticeId));
  }
}
