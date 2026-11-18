/// What is dragged from the system over the app.
enum DropKind {
  /// Files, sent with Files.
  files,

  /// Text, sent to the device's clipboard.
  text,

  /// A web link, opened on the device with Handoff.
  link;

  /// [text] dropped as a link when the system said so, or when it is a lone
  /// web address; otherwise as text.
  static DropKind ofText(String text, {required bool isLink}) {
    if (isLink) {
      return .link;
    }

    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);
    final isWebAddress =
        !trimmed.contains(RegExp(r'\s')) &&
        uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
    if (isWebAddress) {
      return .link;
    }

    return .text;
  }
}
