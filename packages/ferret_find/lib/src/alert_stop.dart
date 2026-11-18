/// Why the platform stopped ringing on its own, without Dart asking.
enum AlertStop {
  /// Someone tapped "Found it" or dismissed the ringing notice.
  found,

  /// Someone pressed a volume key while it rang (Android).
  volumeKey,

  /// The platform's own safety limit ran out.
  timeout;

  /// The reason as the native side names it, or null when unknown.
  static AlertStop? fromNative(String reason) => switch (reason) {
    'found' => found,
    'volume_key' => volumeKey,
    'timeout' => timeout,
    _ => null,
  };
}
