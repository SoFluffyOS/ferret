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
    this.activeCalls,
  });

  final CallsControl control;
  final String deviceId;
  final String deviceName;

  /// See [DialerViewModel].
  final Map<String, List<CallLogEntry>>? lastLoaded;

  /// The calls going on, to show this phone's next to the dialer.
  final ActiveCallsViewModel? activeCalls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.callsL10n;

    // In a window's pane the toolbar already says "Calls · Pixel 9";
    // naming the page the same lets it leave the title out.
    final isSection = PaneToolbarScope.titleOf(context) != null;

    return FerretPage(
      title: switch (isSection) {
        true => l10n.title,
        false => l10n.dialerTitle(deviceName),
      },
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider(
          create: (_) => DialerViewModel(
            control: control,
            deviceId: deviceId,
            deviceName: deviceName,
            lastLoaded: lastLoaded,
          ),
          child: DialerFrame(
            ongoing: switch (activeCalls) {
              final activeCalls? => ChangeNotifierProvider.value(
                value: activeCalls,
                child: CallCardFrame(deviceId: deviceId),
              ),
              null => null,
            },
          ),
        ),
      ],
    );
  }
}
