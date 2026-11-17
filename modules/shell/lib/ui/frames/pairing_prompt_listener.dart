import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
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

  Future<void> _show(PairingPrompt prompt) async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    await PairingPromptDialog.show(navigatorContext, prompt);
  }
}
