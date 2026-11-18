import 'package:feature_kit/feature_kit.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/ui/frames/frames.dart';
import 'package:flutter/widgets.dart';

/// Opened by "Ring" on a device: shows the ring live with Stop.
class OutgoingRingPage extends StatelessWidget {
  const OutgoingRingPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) => FerretPage(
    title: context.findL10n.findDevice(deviceName),
    children: [OutgoingRingFrame(deviceId: deviceId)],
  );
}
