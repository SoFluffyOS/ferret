/// Reads values out of JSON that came from another device, so nothing is
/// trusted to have the right type, length or characters.
abstract final class JsonFields {
  static final _control = RegExp(r'[\x00-\x1f\x7f]');

  /// [value] as a display string: no control characters, at most [max] long.
  /// Null when it isn't a string or is empty.
  static String? text(Object? value, {int max = 128}) {
    if (value is! String) {
      return null;
    }

    final cleaned = value.replaceAll(_control, ' ').trim();
    if (cleaned.isEmpty) {
      return null;
    }

    if (cleaned.length <= max) {
      return cleaned;
    }

    return cleaned.substring(0, max);
  }

  /// [value] as it is, when it is a string no longer than [max].
  static String? raw(Object? value, {int max = 1024}) {
    if (value is! String || value.isEmpty || value.length > max) {
      return null;
    }

    return value;
  }

  /// [value] as a whole number, when it is one.
  static int? integer(Object? value) => switch (value) {
    final int whole => whole,
    final double fraction when fraction == fraction.truncateToDouble() =>
      fraction.toInt(),
    _ => null,
  };

  static Map<String, dynamic>? object(Object? value) => switch (value) {
    final Map<String, dynamic> map => map,
    _ => null,
  };
}
