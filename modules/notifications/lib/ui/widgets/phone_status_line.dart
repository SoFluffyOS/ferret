import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/ui/widgets/status_line.dart';
import 'package:notifications/view_models/view_models.dart';

/// What a paired phone says about its mirroring, in plain words.
class PhoneStatusLine extends StatelessWidget {
  const PhoneStatusLine({super.key, required this.phone});

  final PhoneStatus phone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.notificationsL10n;

    final (text, tone) = switch (phone.state) {
      .offline => (l10n.homeOffline(phone.name), StatusTone.neutral),
      .off => (l10n.homeTurnOn(phone.name), StatusTone.neutral),
      .unreachable => (
        l10n.homeUnreachable(phone.name),
        StatusTone.warning,
      ),
      .checking => (l10n.phoneChecking, StatusTone.neutral),
      .accessOff => (
        l10n.homeAccessOff(phone.name),
        StatusTone.warning,
      ),
      .mirroring => (
        l10n.phoneMirroring(_apps(l10n)),
        StatusTone.good,
      ),
    };

    return StatusLine(text: text, tone: tone);
  }

  String _apps(NotificationsLocalizations l10n) => switch (phone.settings) {
    final settings? => l10n.appsSummary(
      settings.effectiveFilter,
      settings.namedAppCount,
    ),
    null => l10n.appsAll,
  };
}
