import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This device as the others see it: its name, with Rename, and on a
/// computer counted as shared, a way to say only the person uses it.
class ThisDeviceCard extends StatefulWidget {
  const ThisDeviceCard({super.key, required this.engine});

  final FerretEngine engine;

  /// Asks for a new name for this device and tells the other devices.
  static Future<void> rename(BuildContext context, FerretEngine engine) async {
    final l10n = context.shellL10n;
    final name = await InputTextDialog.show(
      context,
      title: l10n.settingsRenameTitle,
      labelText: l10n.onboardNameLabel,
      initialValue: engine.device.name,
      cancelText: l10n.cancel,
      confirmText: l10n.settingsRename,
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }

    await engine.rename(name);
  }

  @override
  State<ThisDeviceCard> createState() => _ThisDeviceCardState();
}

class _ThisDeviceCardState extends State<ThisDeviceCard> {
  @override
  Widget build(BuildContext context) {
    final device = widget.engine.device;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return SurfaceCard(
      child: Row(
        children: [
          Icon(
            deviceIconFor(device.formFactor, device.platform),
            size: Spacing.d24,
            color: palette.text,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  device.name,
                  style: typography.base1.copyWith(color: palette.text),
                  overflow: .ellipsis,
                ),
                for (final line in _sharingLines(l10n)) ...[
                  Spacing.vertical(Spacing.d2),
                  Text(
                    line,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Spacing.h12,
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                GhostButton(
                  mainAxisSize: .min,
                  label: l10n.settingsRename,
                  onPressed: _rename,
                ),
                if (_sharedComputer.isShared) ...[
                  Spacing.v8,
                  GhostButton(
                    mainAxisSize: .min,
                    label: l10n.thisDeviceOnlyMe,
                    tooltip: l10n.thisDeviceOnlyMeHint(ThisComputer.here),
                    semanticLabel: l10n.thisDeviceOnlyMeHint(ThisComputer.here),
                    onPressed: _onlyMe,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Said only on a computer several accounts run Ferret on: why the
  /// name carries the account, and the port when the usual one is taken.
  List<String> _sharingLines(ShellLocalizations l10n) {
    final engine = widget.engine;
    final isShared = _sharedComputer.isShared;

    return [
      if (isShared) l10n.thisDeviceShared(ThisComputer.here),
      if (engine.usesFallbackPort)
        l10n.thisDeviceOtherPort('${engine.port}', '${engine.preferredPort}'),
    ];
  }

  SharedComputer get _sharedComputer => SharedComputer(
    widget.engine.settings,
    environment: Platform.environment,
  );

  Future<void> _onlyMe() async {
    await _sharedComputer.onlyMe(widget.engine);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _rename() async {
    await ThisDeviceCard.rename(context, widget.engine);
    if (mounted) {
      setState(() {});
    }
  }
}
