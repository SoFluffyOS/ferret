import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/status_line.dart';
import 'package:notifications/view_models/view_models.dart';

/// What a connected phone says about its mirroring, in plain words.
class PhoneStatusLine extends StatelessWidget {
  const PhoneStatusLine({super.key, required this.phone});

  final PhoneStatus phone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.notificationsL10n;

    final (text, tone) = switch (phone) {
      PhoneStatus(unreachable: true) => (
        l10n.phoneUnreachable,
        StatusTone.warning,
      ),
      PhoneStatus(settings: null) => (l10n.phoneChecking, StatusTone.neutral),
      PhoneStatus(settings: final settings?) when !settings.enabled => (
        l10n.phoneMirroringOff,
        StatusTone.warning,
      ),
      PhoneStatus(settings: final settings?) when !settings.accessGranted => (
        l10n.phoneAccessOff,
        StatusTone.warning,
      ),
      PhoneStatus(settings: final settings?) => (
        l10n.phoneMirroring(settings.allowedPackages.length),
        StatusTone.good,
      ),
    };

    return StatusLine(text: text, tone: tone);
  }
}
