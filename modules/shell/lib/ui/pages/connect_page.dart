import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Connects to a paired device by its address, for networks that hide
/// devices from each other.
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController _address = .new();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.shellL10n;

    return FerretPage(
      title: l10n.connectTitle,
      backLabel: l10n.back,
      children: [
        Text(
          l10n.connectBody,
          style: context.fluffyTheme.typography.body2.copyWith(
            color: palette.mutedText,
          ),
        ),
        Spacing.v12,
        InputText(
          controller: _address,
          label: l10n.pairAddressLabel,
          hintText: l10n.pairAddressHint,
          keyboardType: .url,
          onSubmitted: (_) => _connect(),
        ),
        Spacing.v12,
        Button(variant: .primary, label: l10n.pairConnect, onPressed: _connect),
      ],
    );
  }

  Future<void> _connect() async {
    final engine = ShellScope.read(context).featureContext.engine;
    final navigator = Navigator.of(context);
    final text = _address.text.trim();
    final separator = text.lastIndexOf(':');
    final (host, port) = switch (separator > 0) {
      true => (
        text.substring(0, separator),
        int.tryParse(text.substring(separator + 1)) ?? FerretEngine.defaultPort,
      ),
      false => (text, FerretEngine.defaultPort),
    };
    if (host.isEmpty) {
      return;
    }

    await engine.connect(host, port);
    navigator.pop();
  }
}
