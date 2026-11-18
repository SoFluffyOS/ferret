import 'package:calls/l10n/l10n.dart';
import 'package:calls/services/services.dart';
import 'package:calls/ui/frames/frames.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/calls.dart';
import 'package:provider/provider.dart';

/// "Call…" for one phone: the dialer and the phone's recent calls.
class DialerPage extends StatelessWidget {
  const DialerPage({
    super.key,
    required this.control,
    required this.deviceId,
    required this.deviceName,
    this.lastLoaded,
  });

  final CallsControl control;
  final String deviceId;
  final String deviceName;

  /// See [DialerViewModel].
  final Map<String, List<CallLogEntry>>? lastLoaded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.callsL10n;

    return FerretPage(
      title: l10n.dialerTitle(deviceName),
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider(
          create: (_) => DialerViewModel(
            control: control,
            deviceId: deviceId,
            deviceName: deviceName,
            lastLoaded: lastLoaded,
          ),
          child: const DialerFrame(),
        ),
      ],
    );
  }
}
