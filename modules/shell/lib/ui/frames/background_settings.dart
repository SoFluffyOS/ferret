import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/bootstrap/bootstrap.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/login_settings.dart';

/// Android: keep running in the background, and start with the phone.
/// Computers: start at login ([LoginSettings]). An iPhone has neither: iOS
/// runs Ferret only while it is open.
class BackgroundSettings extends StatefulWidget {
  const BackgroundSettings({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<BackgroundSettings> createState() => _BackgroundSettingsState();
}

class _BackgroundSettingsState extends State<BackgroundSettings> {
  late bool _keepRunning;
  late bool _startOnBoot;

  @override
  void initState() {
    super.initState();
    _keepRunning =
        widget.settings.get<bool>(SystemBinding.backgroundServiceKey) ?? true;
    _startOnBoot = BootChoice(widget.settings).startsOnBoot;
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == .iOS) {
      return const SizedBox.shrink();
    }

    if (defaultTargetPlatform != .android) {
      return LoginSettings(settings: widget.settings);
    }

    final l10n = context.shellL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsBackground),
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.settingsKeepRunning,
              body: l10n.settingsKeepRunningBody,
              value: _keepRunning,
              onChanged: (value) => _set(
                SystemBinding.backgroundServiceKey,
                value,
                () => _keepRunning = value,
              ),
            ),
            SettingSwitchRow(
              title: l10n.settingsStartOnBoot(ThisComputer.handheld),
              value: _startOnBoot,
              onChanged: (value) {
                setState(() => _startOnBoot = value);
                unawaited(BootChoice(widget.settings).answer(start: value));
              },
            ),
          ],
        ),
      ],
    );
  }

  void _set(String key, bool value, VoidCallback apply) {
    setState(apply);
    unawaited(widget.settings.set(key, value));
  }
}
