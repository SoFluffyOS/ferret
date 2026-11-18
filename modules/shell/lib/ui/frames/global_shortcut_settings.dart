import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The keys that open the menubar popover from any app: what they are,
/// Change to press new ones, and a way to turn them off. Only on a Mac,
/// where there is a menubar popover to open.
class GlobalShortcutSettings extends StatefulWidget {
  const GlobalShortcutSettings({super.key});

  @override
  State<GlobalShortcutSettings> createState() => _GlobalShortcutSettingsState();
}

class _GlobalShortcutSettingsState extends State<GlobalShortcutSettings> {
  late final SettingsStore _settings;
  FerretMenubar? _menubar;
  MenubarShortcut? _shortcut;
  bool _isRecording = false;
  bool _wasRefused = false;

  @override
  void initState() {
    super.initState();
    _settings = ShellScope.read(context).featureContext.engine.settings;
    _menubar = context.read<FerretMenubar?>();
    _shortcut = GlobalShortcut.read(_settings);
  }

  @override
  void dispose() {
    if (_isRecording) {
      unawaited(_menubar?.cancelRecording());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menubar = _menubar;
    if (menubar == null || !menubar.isSupported) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final shortcut = _shortcut;
    final value = switch (shortcut) {
      final shortcut? => shortcut.label,
      null => l10n.settingsShortcutOff,
    };
    final note = switch ((_isRecording, _wasRefused)) {
      (true, _) => l10n.settingsShortcutRecording,
      (false, true) => l10n.settingsShortcutTaken,
      (false, false) => l10n.settingsShortcutBody,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.settingsShortcutTitle,
                  style: typography.base1.copyWith(color: palette.text),
                ),
              ),
              Spacing.h8,
              Text(
                value,
                style: typography.base1.copyWith(color: palette.mutedText),
              ),
            ],
          ),
          Spacing.v4,
          Text(
            note,
            style: typography.caption1.copyWith(
              color: switch (_wasRefused && !_isRecording) {
                true => palette.warning,
                false => palette.mutedText,
              },
            ),
          ),
          Spacing.v12,
          Wrap(
            spacing: Spacing.d8,
            runSpacing: Spacing.d8,
            children: [
              Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.settingsShortcutChange,
                onPressed: switch (_isRecording) {
                  true => null,
                  false => () => unawaited(_record(menubar)),
                },
              ),
              Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: switch (shortcut) {
                  null => l10n.settingsShortcutTurnOn,
                  _ => l10n.settingsShortcutTurnOff,
                },
                onPressed: switch (_isRecording) {
                  true => null,
                  false => () => unawaited(
                    _use(menubar, switch (shortcut) {
                      null => GlobalShortcut.fallback,
                      _ => null,
                    }),
                  ),
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _record(FerretMenubar menubar) async {
    setState(() => _isRecording = true);
    final recorded = await menubar.recordShortcut();
    if (!mounted) {
      return;
    }

    setState(() => _isRecording = false);
    if (recorded == null) {
      return;
    }

    await _use(menubar, recorded);
  }

  /// Keys the Mac refuses leave the ones before in place.
  Future<void> _use(FerretMenubar menubar, MenubarShortcut? shortcut) async {
    final previous = _shortcut;
    final taken = await menubar.setGlobalShortcut(shortcut);
    if (!taken) {
      await menubar.setGlobalShortcut(previous);
      _show(refused: true);
      return;
    }

    await GlobalShortcut.write(_settings, shortcut);
    _shortcut = shortcut;
    _show(refused: false);
  }

  void _show({required bool refused}) {
    if (!mounted) {
      return;
    }

    setState(() => _wasRefused = refused);
  }
}
