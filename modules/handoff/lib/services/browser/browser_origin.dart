/// Which requests may reach the browser bridge. Any web page can open a
/// WebSocket to 127.0.0.1, but only an extension sends an extension origin,
/// so everything else is turned away before the upgrade.
abstract final class BrowserOrigin {
  static final _chromium = RegExp(r'^chrome-extension://[a-p]{32}$');
  static final _firefox = RegExp(
    r'^moz-extension://[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static final _loopbackHost = RegExp(
    r'^(127\.0\.0\.1|localhost|\[::1\])(:\d{1,5})?$',
  );

  /// A Chromium (`chrome-extension://`) or Firefox (`moz-extension://`)
  /// extension origin, exactly as browsers send it.
  static bool isExtension(String? origin) {
    if (origin == null) {
      return false;
    }

    return _chromium.hasMatch(origin) || _firefox.hasMatch(origin);
  }

  /// A name for the browser family behind [origin], for when the extension
  /// didn't say which browser it runs in.
  static String familyOf(String origin) {
    if (origin.startsWith('moz-extension://')) {
      return 'Firefox';
    }

    return 'Chromium';
  }

  /// The Host header names this computer. The bridge only listens on
  /// loopback, so a different name means DNS rebinding or a proxy.
  static bool isLoopbackHost(String? host) {
    if (host == null) {
      return false;
    }

    return _loopbackHost.hasMatch(host.trim().toLowerCase());
  }
}
