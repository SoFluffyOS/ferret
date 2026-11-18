/// Reads the ANCS date attribute, `yyyyMMdd'T'HHmmSS` in the iPhone's local
/// time (which this computer is assumed to share). Null when it isn't one.
DateTime? parseAncsDate(String text) {
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }

  final parts = [
    for (var group = 1; group <= 6; group++)
      int.parse(match.group(group) ?? ''),
  ];
  final [year, month, day, hour, minute, second] = parts;
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }

  if (hour > 23 || minute > 59 || second > 59) {
    return null;
  }

  return DateTime(year, month, day, hour, minute, second);
}
