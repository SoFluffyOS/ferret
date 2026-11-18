import 'dart:convert';

/// What Ferret reads from an app's AssistContent structured data (JSON-LD).
///
/// Standard schema.org keys: `url`, `name` or `headline`, and `geo` with
/// `latitude`/`longitude`. Ferret's own keys sit under `ferret`:
/// `deepLink`, `fallbackUri`, `apps` (`android`, `apple`, `linux`,
/// `windows`), `state` and `stateType`.
class StructuredData {
  const StructuredData({
    this.url = '',
    this.name = '',
    this.latitude,
    this.longitude,
    this.deepLink = '',
    this.fallbackUri = '',
    this.androidPackage = '',
    this.appleBundleId = '',
    this.linuxDesktopId = '',
    this.windowsAppId = '',
    this.state = '',
    this.stateType = '',
  });

  static const empty = StructuredData();

  static StructuredData parse(String? json) {
    if (json == null || json.trim().isEmpty) {
      return empty;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return empty;
    }

    final root = _mainObject(decoded);
    if (root == null) {
      return empty;
    }

    final ferret = switch (root['ferret']) {
      final Map<String, Object?> map => map,
      _ => const <String, Object?>{},
    };
    final apps = switch (ferret['apps']) {
      final Map<String, Object?> map => map,
      _ => const <String, Object?>{},
    };
    final geo = switch (root['geo']) {
      final Map<String, Object?> map => map,
      _ => const <String, Object?>{},
    };

    return StructuredData(
      url: _string(root['url']),
      name: switch (_string(root['name'])) {
        '' => _string(root['headline']),
        final name => name,
      },
      latitude: _number(geo['latitude']),
      longitude: _number(geo['longitude']),
      deepLink: _string(ferret['deepLink']),
      fallbackUri: _string(ferret['fallbackUri']),
      androidPackage: _string(apps['android']),
      appleBundleId: _string(apps['apple']),
      linuxDesktopId: _string(apps['linux']),
      windowsAppId: _string(apps['windows']),
      state: _string(ferret['state']),
      stateType: _string(ferret['stateType']),
    );
  }

  final String url;
  final String name;
  final double? latitude;
  final double? longitude;
  final String deepLink;
  final String fallbackUri;
  final String androidPackage;
  final String appleBundleId;
  final String linuxDesktopId;
  final String windowsAppId;
  final String state;
  final String stateType;

  /// A `geo:` URI when the data names a place.
  String get geoUri => switch ((latitude, longitude)) {
    (final latitude?, final longitude?) => 'geo:$latitude,$longitude',
    _ => '',
  };

  static Map<String, Object?>? _mainObject(Object? decoded) =>
      switch (decoded) {
        {'@graph': [final Map<String, Object?> first, ...]} => first,
        final Map<String, Object?> map => map,
        [final Map<String, Object?> first, ...] => first,
        _ => null,
      };

  static String _string(Object? value) => switch (value) {
    final String text => text.trim(),
    _ => '',
  };

  static double? _number(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
}
