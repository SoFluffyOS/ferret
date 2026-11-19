import 'package:feature_kit/services/app_locale.dart';

/// Names in a row, such as the devices a copy went to, with the comma of
/// the language Ferret shows: "Pixel 7, iPad" in English, "Pixel 7、iPad"
/// in Japanese and Chinese, "Pixel 7، iPad" in Arabic.
abstract final class ListText {
  static const _separators = {
    'ja': '、',
    'zh': '、',
    'ar': '، ',
    'fa': '، ',
    'ur': '، ',
  };

  /// What goes between two items in [localeName] (a language tag such as
  /// `ja` or `pt_BR`), or in the language Ferret shows when left out.
  static String separator([String? localeName]) {
    final language = (localeName ?? AppLocale.shown.languageCode)
        .split(RegExp('[-_]'))
        .first
        .toLowerCase();

    return _separators[language] ?? ', ';
  }

  /// [items] as one line. Strings built outside a widget leave
  /// [localeName] out; a widget passes its strings' `localeName`.
  static String join(Iterable<String> items, {String? localeName}) =>
      items.join(separator(localeName));
}
