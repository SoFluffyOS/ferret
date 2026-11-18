import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This device: its name (with Rename), its id, and the address to type on
/// another device when they can't find each other.
class ThisDeviceCard extends StatefulWidget {
  const ThisDeviceCard({super.key, required this.engine});

  final FerretEngine engine;

  @override
  State<ThisDeviceCard> createState() => _ThisDeviceCardState();
}

class _ThisDeviceCardState extends State<ThisDeviceCard> {
  late final Future<String?> _address = _firstAddress();

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final muted = typography.caption1.copyWith(color: palette.mutedText);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  engine.device.name,
                  style: typography.base1.copyWith(color: palette.text),
                ),
              ),
              Button(
                variant: .secondary,
                label: l10n.settingsRename,
                onPressed: _rename,
              ),
            ],
          ),
          Spacing.v6,
          Text(
            l10n.settingsDeviceId(
              DeviceIdentity.format(engine.identity.deviceId),
            ),
            style: muted,
          ),
          FutureBuilder<String?>(
            future: _address,
            builder: (context, snapshot) {
              final host = snapshot.data;
              if (host == null) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    l10n.settingsAddress('$host:${engine.port}'),
                    style: muted,
                  ),
                  Spacing.v4,
                  Text(
                    l10n.settingsAddressHint,
                    style: typography.caption2.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rename() async {
    final l10n = context.shellL10n;
    final name = await InputTextDialog.show(
      context,
      title: l10n.settingsRenameTitle,
      labelText: l10n.onboardNameLabel,
      initialValue: widget.engine.device.name,
      cancelText: l10n.cancel,
      confirmText: l10n.settingsRename,
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }

    await widget.engine.rename(name);
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _firstAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && !address.isLinkLocal) {
            return address.address;
          }
        }
      }
    } on Object {
      return null;
    }

    return null;
  }
}
