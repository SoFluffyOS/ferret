/// A place from a `geo:` URI (RFC 5870), and map links for devices that
/// can't open `geo:` themselves.
class GeoLink {
  const GeoLink({
    required this.latitude,
    required this.longitude,
    this.query = '',
  });

  static GeoLink? parse(String uri) {
    final trimmed = uri.trim();
    if (!trimmed.toLowerCase().startsWith('geo:')) {
      return null;
    }

    final body = trimmed.substring(4);
    final queryStart = body.indexOf('?');
    final path = switch (queryStart) {
      < 0 => body,
      _ => body.substring(0, queryStart),
    };
    final params = switch (queryStart) {
      < 0 => const <String, String>{},
      _ => _queryParameters(body.substring(queryStart + 1)),
    };
    final coordinates = path.split(';').first.split(',');
    if (coordinates.length < 2) {
      return null;
    }

    final latitude = double.tryParse(coordinates[0]);
    final longitude = double.tryParse(coordinates[1]);
    if (latitude == null || longitude == null) {
      return null;
    }

    if (latitude.abs() > 90 || longitude.abs() > 180) {
      return null;
    }

    return GeoLink(
      latitude: latitude,
      longitude: longitude,
      query: params['q'] ?? '',
    );
  }

  final double latitude;
  final double longitude;

  /// A search such as an address, used when the coordinates are 0,0.
  final String query;

  bool get _hasCoordinates => latitude != 0 || longitude != 0;

  String get appleMapsUrl {
    final parameters = <String, String>{
      if (_hasCoordinates) 'll': '$latitude,$longitude',
      if (query.isNotEmpty) 'q': query,
    };
    return Uri.https('maps.apple.com', '/', parameters).toString();
  }

  String get openStreetMapUrl {
    if (!_hasCoordinates) {
      return Uri.https('www.openstreetmap.org', '/search', {
        'query': query,
      }).toString();
    }

    return Uri.https('www.openstreetmap.org', '/', {
      'mlat': '$latitude',
      'mlon': '$longitude',
    }).replace(fragment: 'map=16/$latitude/$longitude').toString();
  }

  static Map<String, String> _queryParameters(String query) {
    try {
      return Uri.splitQueryString(query);
    } on FormatException {
      return const {};
    }
  }
}
