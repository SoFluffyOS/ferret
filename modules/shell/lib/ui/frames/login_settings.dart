import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// Start Ferret when you log in: in the tray on Windows and Linux, in the
/// menu bar on a Mac.
class LoginSettings extends StatefulWidget {
  const LoginSettings({
    super.key,
    required this.settings,
    this.login,
    this.tray,
  });

  final SettingsStore settings;

  /// Whether a tray icon shows; [TrayStatus.shows] by default. Without
  /// one, Ferret opens its window at login.
  final ValueListenable<bool>? tray;

  /// The system's login items; the real ones by default.
  final StartAtLogin? login;

  /// What was asked last, for a Flatpak, where the portal keeps the truth.
  static const startAtLoginKey = 'desktop.start_at_login';

  @override
  State<LoginSettings> createState() => _LoginSettingsState();
}

class _LoginSettingsState extends State<LoginSettings> {
  late final StartAtLogin _login = widget.login ?? StartAtLogin();
  bool _enabled = false;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    final remembered =
        widget.settings.get<bool>(LoginSettings.startAtLoginKey) ?? false;
    final enabled = await _login.isEnabled(remembered: remembered);
    if (!mounted) {
      return;
    }

    setState(() => _enabled = enabled);
  }

  Future<void> _set(bool enabled) async {
    setState(() {
      _enabled = enabled;
      _denied = false;
    });
    await widget.settings.set(LoginSettings.startAtLoginKey, enabled);
    if (await _login.setEnabled(enabled) || !mounted) {
      return;
    }

    await widget.settings.set(LoginSettings.startAtLoginKey, false);
    setState(() {
      _enabled = false;
      _denied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_login.isSupported) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsBackground),
        GroupedCard(
          children: [
            ValueListenableBuilder(
              valueListenable: widget.tray ?? TrayStatus.shows,
              builder: (context, hasTray, _) => SettingSwitchRow(
                title: l10n.settingsStartAtLogin,
                body: switch ((_denied, hasTray)) {
                  (true, _) => l10n.settingsStartAtLoginDenied,
                  (false, false) => l10n.settingsStartAtLoginNoTray,
                  (false, true) => l10n.settingsStartAtLoginBody(
                    ThisComputer.here,
                  ),
                },
                value: _enabled,
                onChanged: (value) => unawaited(_set(value)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
