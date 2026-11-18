import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What to type on another device when the two can't find each other: this
/// device's ID and its address on the network.
class ConnectByHandCard extends StatefulWidget {
  const ConnectByHandCard({super.key, required this.engine});

  final FerretEngine engine;

  @override
  State<ConnectByHandCard> createState() => _ConnectByHandCardState();
}

class _ConnectByHandCardState extends State<ConnectByHandCard> {
  late final Future<String?> _address = _firstAddress();

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _Fact(
            label: l10n.settingsDeviceIdLabel,
            value: DeviceIdentity.format(engine.identity.deviceId),
          ),
          FutureBuilder<String?>(
            future: _address,
            builder: (context, snapshot) {
              final host = snapshot.data;
              if (host == null) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: .stretch,
                children: [
                  Spacing.v12,
                  _Fact(
                    label: l10n.settingsAddressLabel,
                    value: '$host:${engine.port}',
                  ),
                  Spacing.v8,
                  Text(
                    l10n.settingsAddressHint,
                    style: typography.caption1.copyWith(
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

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Row(
      children: [
        Text(label, style: typography.base2.copyWith(color: palette.text)),
        Spacing.h12,
        Expanded(
          child: Text(
            value,
            textAlign: .end,
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
        ),
      ],
    );
  }
}
