import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Reach Pixel 7 away from home": the switch that lets Ferret dial a
/// paired device over the user's own VPN, and an address to try.
class DeviceVpnPage extends StatefulWidget {
  const DeviceVpnPage({super.key, required this.deviceId});

  final String deviceId;

  /// A word for the device's page: "On" or "Off".
  static String summary(BuildContext context, TrustedDevice device) =>
      switch (device.reachOverVpn) {
        true => context.shellL10n.settingsOn,
        false => context.shellL10n.settingsOff,
      };

  @override
  State<DeviceVpnPage> createState() => _DeviceVpnPageState();
}

class _DeviceVpnPageState extends State<DeviceVpnPage> {
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final engine = ShellScope.read(context).featureContext.engine;
    _address = TextEditingController(
      text: engine.trustStore[widget.deviceId]?.reachAt ?? '',
    );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final engine = ShellScope.read(context).featureContext.engine;
    await engine.setReachAt(widget.deviceId, _address.text);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final status = context.select<EngineHost, DeviceStatus?>(
      (host) => host.statusOf(widget.deviceId),
    );
    final l10n = context.shellL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final note = typography.base2.copyWith(color: palette.mutedText);

    if (status == null) {
      return FerretPage(title: '', backLabel: l10n.back, children: const []);
    }

    final device = status.device;
    final here = l10n.here(engine.device);

    return FerretPage(
      title: l10n.vpnTitle(device.name),
      backLabel: l10n.back,
      width: .narrow,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
          child: Text(l10n.vpnIntro(device.name), style: note),
        ),
        Spacing.v16,
        GroupedCard(
          children: [
            MergeSemantics(
              child: GroupedRow(
                title: l10n.vpnSwitch(device.name),
                subtitle: l10n.vpnSwitchHint,
                trailing: SwitchToggle(
                  value: device.reachOverVpn,
                  onChanged: (reach) => unawaited(
                    engine.setReachOverVpn(widget.deviceId, reach: reach),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (status.reachedOverVpn) ...[
          Spacing.v12,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
            child: Text(
              '${l10n.deviceReachedOverVpn}. ${l10n.vpnSlow}',
              style: note,
            ),
          ),
        ],
        if (device.reachOverVpn) ...[
          Spacing.v16,
          InputText(
            controller: _address,
            label: l10n.vpnReachAt,
            hintText: l10n.vpnReachAtHint,
            keyboardType: .url,
            onSubmitted: (_) => unawaited(_saveAddress()),
          ),
          Spacing.v8,
          Row(
            children: [
              Button(
                variant: .ghost,
                mainAxisSize: .min,
                label: l10n.vpnSaveAddress,
                onPressed: () => unawaited(_saveAddress()),
              ),
            ],
          ),
          Spacing.v8,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
            child: Text(
              switch (device.vpnAddresses.isEmpty) {
                true => l10n.vpnNoAddresses(device.name),
                false => l10n.vpnAddresses(
                  device.name,
                  device.vpnAddresses.join(', '),
                ),
              },
              style: note,
            ),
          ),
        ],
        Spacing.v16,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
          child: Text(
            l10n.vpnPrivacy(device.name, here),
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ),
      ],
    );
  }
}
