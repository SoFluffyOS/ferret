/// Which URIs an activity may carry, so a paired device can't make this one
/// open local files or run script.
abstract final class LinkRules {
  static const _web = {'http', 'https'};
  static const _plain = {'http', 'https', 'mailto', 'tel', 'sms', 'geo'};
  static const _blocked = {
    'about',
    'android-app',
    'blob',
    'chrome',
    'content',
    'data',
    'file',
    'filesystem',
    'intent',
    'javascript',
    'jar',
    'ms-settings',
    'shell',
    'smb',
    'vbscript',
    'x-apple.systempreferences',
  };

  static final _scheme = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*):');

  /// The lower-case scheme of [uri], or null when it has none.
  static String? schemeOf(String uri) {
    if (_scheme.firstMatch(uri.trim()) case final match?) {
      return match.group(1)?.toLowerCase();
    }

    return null;
  }

  static bool isWeb(String uri) => _web.contains(schemeOf(uri));

  static bool isGeo(String uri) => schemeOf(uri) == 'geo';

  /// http(s), mailto, tel, sms and geo: safe to hand to the system.
  static bool isPlain(String uri) => _plain.contains(schemeOf(uri));

  /// An app's own scheme (or a web link) that may open in that app.
  static bool isAppLink(String uri) {
    final scheme = schemeOf(uri);
    if (scheme == null) {
      return false;
    }

    return !_blocked.contains(scheme);
  }
}
