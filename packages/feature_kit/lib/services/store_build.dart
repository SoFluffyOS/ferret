/// The app store a build is made for. Set when building, as in
/// `flutter build appbundle --dart-define=FERRET_STORE=play`; the Android
/// Gradle build reads the same value. Builds Ferret publishes itself
/// (GitHub, the website) leave it out.
enum StoreBuild {
  /// Published by Ferret itself.
  none,

  /// Google Play: only Play updates the app, and payments go through Play.
  play;

  /// This build's.
  static final current = parse(const String.fromEnvironment('FERRET_STORE'));

  /// The store [name] means; anything unknown is [none].
  static StoreBuild parse(String name) => switch (name.trim().toLowerCase()) {
    'play' => play,
    _ => none,
  };
}
