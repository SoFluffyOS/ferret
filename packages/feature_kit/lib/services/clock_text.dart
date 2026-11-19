import 'package:intl/intl.dart';

/// Times of day and lengths of time, written the same way on every card.
abstract final class ClockText {
  /// [at] as a time of day in [locale], such as "3:07 PM". intl throws for
  /// a locale whose date symbols were never loaded; the 24-hour default
  /// beats no time at all.
  static String timeOfDay(String locale, DateTime at) {
    try {
      return DateFormat.jm(locale).format(at);
    } on Object {
      return DateFormat.Hm().format(at);
    }
  }

  /// [length] as `m:ss`, or `h:mm:ss` from one hour, such as a call or a
  /// song. A negative length reads as `0:00`.
  static String duration(Duration length) {
    final clamped = switch (length.isNegative) {
      true => Duration.zero,
      false => length,
    };
    final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');
    if (clamped.inHours == 0) {
      return '${clamped.inMinutes}:$seconds';
    }

    final minutes = (clamped.inMinutes % 60).toString().padLeft(2, '0');
    return '${clamped.inHours}:$minutes:$seconds';
  }
}
