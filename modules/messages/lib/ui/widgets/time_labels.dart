import 'package:intl/intl.dart';
import 'package:messages/l10n/l10n.dart';

/// Dates as a conversation list and a thread show them.
class TimeLabels {
  TimeLabels(this.l10n, String localeName, this.now)
    : localeName = _loadedLocale(localeName);

  final MessagesLocalizations l10n;
  final String localeName;
  final DateTime now;

  /// The time today, the weekday this week, or the date.
  String short(DateTime at) {
    final days = _dayOf(now).difference(_dayOf(at)).inDays;
    if (days == 0) {
      return DateFormat.jm(localeName).format(at);
    }

    if (days > 0 && days < 7) {
      return DateFormat.E(localeName).format(at);
    }

    return DateFormat.yMd(localeName).format(at);
  }

  /// A divider between days in a thread.
  String day(DateTime at) {
    final days = _dayOf(now).difference(_dayOf(at)).inDays;
    if (days == 0) {
      return l10n.today;
    }

    if (days == 1) {
      return l10n.yesterday;
    }

    if (at.year == now.year) {
      return DateFormat.MMMEd(localeName).format(at);
    }

    return DateFormat.yMMMEd(localeName).format(at);
  }

  String time(DateTime at) => DateFormat.jm(localeName).format(at);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// intl throws for a locale whose date symbols were never loaded; its
  /// built-in English is better than no date.
  static String _loadedLocale(String localeName) {
    try {
      DateFormat.jm(localeName);
      return localeName;
    } on Object {
      return _builtInLocale;
    }
  }

  static const _builtInLocale = 'en_US';

  static DateTime _dayOf(DateTime at) => DateTime(at.year, at.month, at.day);
}
