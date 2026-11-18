/// Cleans up phone numbers typed by people.
abstract final class PhoneNumbers {
  static const maxLength = 32;

  static final RegExp _decoration = RegExp(r'[\s\-(). /]');
  static final RegExp _dialable = RegExp(r'^\+?[0-9*#]+$');

  /// [typed] without spaces, dashes, dots and brackets, or null when what is
  /// left is not something a phone can dial.
  static String? dialable(String typed) {
    final number = typed.replaceAll(_decoration, '');
    if (number.length > maxLength || !_dialable.hasMatch(number)) {
      return null;
    }

    return number;
  }
}
