import 'package:shell/l10n/generated/shell_localizations.dart';

extension LastSeenText on ShellLocalizations {
  /// How long ago a device was last around, such as "Seen 5 min ago", or
  /// that it is offline when it was never seen.
  String lastSeen(DateTime? at) {
    if (at == null) {
      return deviceOffline;
    }

    final elapsed = DateTime.now().difference(at);
    return switch (elapsed) {
      Duration(inMinutes: < 1) => deviceLastSeenJustNow,
      Duration(inHours: < 1) => deviceLastSeenMinutes(elapsed.inMinutes),
      Duration(inDays: < 1) => deviceLastSeenHours(elapsed.inHours),
      _ => deviceLastSeenDays(elapsed.inDays),
    };
  }
}
