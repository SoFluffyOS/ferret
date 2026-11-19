import 'package:intl/intl.dart';

/// When a photo was taken, as a date and a time of day.
abstract final class PhotoDate {
  /// [at] in [locale], such as "Nov 19, 2026 9:41 AM". intl throws for a
  /// locale whose date symbols were never loaded; the default beats none.
  static String format(String locale, DateTime at) {
    try {
      return DateFormat.yMMMd(locale).add_jm().format(at);
    } on Object {
      return DateFormat.yMMMd().add_Hm().format(at);
    }
  }
}
