import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// Settings → Advanced: whether a device running low says so here.
class BatterySettings extends StatefulWidget {
  const BatterySettings({super.key});

  @override
  State<BatterySettings> createState() => _BatterySettingsState();
}

class _BatterySettingsState extends State<BatterySettings> {
  StreamSubscription<String>? _changes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ShellScope.of(context).featureContext.engine.settings;
    unawaited(_changes?.cancel());
    _changes = settings.changes
        .where((key) => key == LowBatteryNotices.enabledKey)
        .listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ShellScope.of(context).featureContext.engine.settings;
    final l10n = context.shellL10n;

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.settingsLowBattery,
          body: l10n.settingsLowBatteryBody,
          value: LowBatteryNotices.isOn(settings),
          onChanged: (value) => unawaited(
            settings.set(LowBatteryNotices.enabledKey, value),
          ),
        ),
      ],
    );
  }
}
