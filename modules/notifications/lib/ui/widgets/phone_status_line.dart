import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
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
      .unreachable => (l10n.phoneUnreachable, StatusTone.warning),
      .checking => (l10n.phoneChecking, StatusTone.neutral),
      .accessOff => (l10n.phoneAccessOff, StatusTone.warning),
      .mirroring => (
        l10n.phoneMirroring(phone.settings?.allowedPackages.length ?? 0),
        StatusTone.good,
      ),
    };

    return StatusLine(text: text, tone: tone);
  }
}
