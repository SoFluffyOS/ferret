/// A browser extension asking to use Ferret. The user compares [code] with
/// the one the extension shows, then allows or denies it.
class BrowserPairRequest {
  const BrowserPairRequest({
    required this.id,
    required this.browser,
    required this.code,
    required this.requestedAt,
  });

  final String id;
  final String browser;

  /// Six digits chosen by the extension.
  final String code;
  final DateTime requestedAt;

  /// The code as people read it, such as "123 456".
  String get spacedCode => switch (code.length) {
    6 => '${code.substring(0, 3)} ${code.substring(3)}',
    _ => code,
  };
}
