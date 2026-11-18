import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/bootstrap/system_binding.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Android only: keep running in the background, and start with the phone.
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
    _startOnBoot =
        widget.settings.get<bool>(SystemBinding.startOnBootKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!FerretSystem().isAndroid) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsBackground),
        SurfaceCard(
          child: Column(
            children: [
              SwitchRow(
                title: l10n.settingsKeepRunning,
                subtitle: l10n.settingsKeepRunningBody,
                value: _keepRunning,
                onChanged: (value) => _set(
                  SystemBinding.backgroundServiceKey,
                  value,
                  () => _keepRunning = value,
                ),
              ),
              Spacing.v12,
              SwitchRow(
                title: l10n.settingsStartOnBoot,
                value: _startOnBoot,
                onChanged: (value) => _set(
                  SystemBinding.startOnBootKey,
                  value,
                  () => _startOnBoot = value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _set(String key, bool value, VoidCallback apply) {
    setState(apply);
    unawaited(widget.settings.set(key, value));
  }
}
