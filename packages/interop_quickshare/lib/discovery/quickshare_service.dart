import 'dart:convert';
import 'dart:math';

/// The names Quick Share uses on mDNS.
abstract final class QuickShareService {
  /// The service type: the first bytes of SHA-256("NearbySharing").
  static const type = '_FC9F5ED42C8A._tcp';

  static const endpointIdLength = 4;
  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const _marker = 0x23;
  static const _serviceId = [0xfc, 0x9f, 0x5e];
  static final _secure = Random.secure();

  /// Four random letters and digits that tell endpoints apart. A new one
  /// each time this device becomes visible, so it can't be followed.
  static String newEndpointId([Random? random]) {
    final source = random ?? _secure;
    return [
      for (var index = 0; index < endpointIdLength; index++)
        _alphabet[source.nextInt(_alphabet.length)],
    ].join();
  }

  /// The mDNS instance name of the endpoint [endpointId].
  static String instanceName(String endpointId) => base64Url
      .encode([_marker, ...ascii.encode(endpointId), ..._serviceId, 0, 0])
      .replaceAll('=', '');

  /// The endpoint id inside an mDNS instance name, or null when the name
  /// isn't a Quick Share one.
  static String? endpointIdOf(String instanceName) {
    final List<int> bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(instanceName));
    } on FormatException {
      return null;
    }

    if (bytes.length < 1 + endpointIdLength + _serviceId.length ||
        bytes[0] != _marker) {
      return null;
    }

    for (final (index, byte) in _serviceId.indexed) {
      if (bytes[1 + endpointIdLength + index] != byte) {
        return null;
      }
    }

    return ascii.decode(
      bytes.sublist(1, 1 + endpointIdLength),
      allowInvalid: true,
    );
  }
}
