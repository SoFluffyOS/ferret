import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';

/// Whether a device paired here joins the user's other devices too, and
/// whether this device shows itself on every network.
class PairingSettings extends StatefulWidget {
  const PairingSettings({super.key, required this.engine});

  final FerretEngine engine;

  @override
  State<PairingSettings> createState() => _PairingSettingsState();
}

class _PairingSettingsState extends State<PairingSettings> {
  late bool _shares = widget.engine.sharesPairings;
  late bool _alwaysVisible = widget.engine.alwaysVisible;

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.settingsSharePairings,
          body: l10n.settingsSharePairingsBody,
          value: _shares,
          onChanged: _set,
        ),
        SettingSwitchRow(
          title: l10n.settingsAlwaysVisible,
          body: l10n.settingsAlwaysVisibleBody,
          value: _alwaysVisible,
          onChanged: _setAlwaysVisible,
        ),
      ],
    );
  }

  void _set(bool shares) {
    setState(() => _shares = shares);
    unawaited(widget.engine.setSharesPairings(shares));
  }

  void _setAlwaysVisible(bool visible) {
    setState(() => _alwaysVisible = visible);
    unawaited(widget.engine.setAlwaysVisible(visible));
  }
}
