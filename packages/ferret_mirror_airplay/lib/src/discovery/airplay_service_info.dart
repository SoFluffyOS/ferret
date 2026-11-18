import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/crypto/crypto.dart';
import 'package:ferret_mirror_airplay/src/discovery/airplay_display.dart';

/// Everything this receiver says about itself, in the two places phones
/// read it: the Bonjour TXT records and the `/info` answer.
///
/// It presents itself as an Apple TV of the generation that still speaks
/// legacy screen mirroring, like the open source receivers do.
class AirPlayServiceInfo {
  const AirPlayServiceInfo({
    required this.name,
    required this.identity,
    required this.publicKey,
    this.display = const AirPlayDisplay(),
  });

  static const airplayType = '_airplay._tcp';
  static const raopType = '_raop._tcp';

  /// The feature bits of a legacy mirroring receiver; bit 27 says it
  /// supports legacy pairing.
  static const features = 0x5A7FFEE6;
  static const model = 'AppleTV3,2';
  static const sourceVersion = '220.68';
  static const _featuresTxt = '0x5A7FFEE6,0x0';
  static const _pairingId = '2e388006-13ba-4041-9a67-25dd4a43d536';
  static const _displayId = 'e0ff8a27-6738-3d56-8a16-cc53aacee925';
  static const _maxLabelBytes = 63;

  /// The name phones list.
  final String name;
  final AirPlayIdentity identity;

  /// This receiver's Ed25519 public key.
  final Uint8List publicKey;
  final AirPlayDisplay display;

  /// The `_airplay._tcp` instance name: [name], cut to fit a DNS label.
  String get airplayInstance => _fit(name, _maxLabelBytes);

  /// The `_raop._tcp` instance name, `AABBCCDDEEFF@Name`.
  String get raopInstance {
    final prefix = '${identity.deviceIdCompact}@';
    return '$prefix${_fit(name, _maxLabelBytes - prefix.length)}';
  }

  /// The host name the addresses are published under. It comes from the
  /// device id, so the computer's real name never goes out.
  String get hostName => 'ferret-${identity.deviceIdCompact.toLowerCase()}';

  Map<String, String> get airplayTxt => {
    'deviceid': identity.deviceIdColons,
    'features': _featuresTxt,
    'flags': '0x4',
    'model': model,
    'pk': _publicKeyHex,
    'pi': _pairingId,
    'srcvers': sourceVersion,
    'vv': '2',
  };

  Map<String, String> get raopTxt => {
    'txtvers': '1',
    'ch': '2',
    'cn': '0,1,2,3',
    'da': 'true',
    'et': '0,3,5',
    'vv': '2',
    'ft': _featuresTxt,
    'am': model,
    'md': '0,1,2',
    'rhd': '5.6.0.0',
    'pw': 'false',
    'sf': '0x4',
    'sr': '44100',
    'ss': '16',
    'sv': 'false',
    'tp': 'UDP',
    'vn': '65537',
    'vs': sourceVersion,
    'pk': _publicKeyHex,
  };

  /// The `/info` answer. [qualifiers] are the extras the phone asked for:
  /// `txtAirPlay` and `txtRAOP` add the TXT records as raw bytes.
  Map<String, Object?> toInfo({List<Object?> qualifiers = const []}) => {
    if (qualifiers.contains('txtAirPlay')) 'txtAirPlay': txtBytes(airplayTxt),
    if (qualifiers.contains('txtRAOP')) 'txtRAOP': txtBytes(raopTxt),
    'deviceID': identity.deviceIdColons,
    'macAddress': identity.deviceIdColons,
    'pk': publicKey,
    'features': features,
    'name': name,
    'pi': _pairingId,
    'vv': 2,
    'statusFlags': 68,
    'keepAliveLowPower': true,
    'sourceVersion': sourceVersion,
    'keepAliveSendStatsAsBody': true,
    'model': model,
    'initialVolume': -20.0,
    'audioLatencies': [
      for (final type in const [100, 101])
        {
          'type': type,
          'audioType': 'default',
          'inputLatencyMicros': 0,
          'outputLatencyMicros': false,
        },
    ],
    'audioFormats': [
      for (final type in const [100, 101])
        {
          'type': type,
          'audioInputFormats': 0x3fffffc,
          'audioOutputFormats': 0x3fffffc,
        },
    ],
    'displays': [
      {
        'uuid': _displayId,
        'widthPhysical': 0,
        'heightPhysical': 0,
        'width': display.width,
        'height': display.height,
        'widthPixels': display.width,
        'heightPixels': display.height,
        'rotation': false,
        'refreshRate': 1 / display.refreshRate,
        'maxFPS': display.maxFps,
        'overscanned': false,
        'features': 14,
      },
    ],
  };

  /// [entries] in the DNS TXT wire format: each `key=value` behind its
  /// length.
  static Uint8List txtBytes(Map<String, String> entries) {
    final out = BytesBuilder();
    for (final MapEntry(:key, :value) in entries.entries) {
      final entry = utf8.encode('$key=$value');
      out
        ..addByte(entry.length)
        ..add(entry);
    }

    return out.takeBytes();
  }

  String get _publicKeyHex => [
    for (final byte in publicKey) byte.toRadixString(16).padLeft(2, '0'),
  ].join();

  /// [text] cut to at most [maxBytes] of UTF-8, never inside a character.
  static String _fit(String text, int maxBytes) {
    final kept = StringBuffer();
    var used = 0;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      used += utf8.encode(character).length;
      if (used > maxBytes) {
        break;
      }

      kept.write(character);
    }

    return '$kept';
  }
}
