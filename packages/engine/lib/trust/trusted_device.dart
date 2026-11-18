import 'dart:convert';
import 'dart:typed_data';

import 'package:protocol/protocol.dart';

/// A device the user paired with.
class TrustedDevice {
  const TrustedDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.formFactor,
    required this.publicKey,
    required this.pairedAt,
    this.lastSeen,
    this.lastHost,
    this.lastPort,
    this.introducedBy,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) => TrustedDevice(
    id: json['id'] as String,
    name: json['name'] as String,
    platform:
        Platform.valueOf(json['platform'] as int) ?? .PLATFORM_UNSPECIFIED,
    formFactor:
        FormFactor.valueOf(json['form_factor'] as int) ??
        .FORM_FACTOR_UNSPECIFIED,
    publicKey: base64Decode(json['public_key'] as String),
    pairedAt: DateTime.fromMillisecondsSinceEpoch(json['paired_at'] as int),
    lastSeen: switch (json['last_seen']) {
      final int millis => DateTime.fromMillisecondsSinceEpoch(millis),
      _ => null,
    },
    lastHost: json['last_host'] as String?,
    lastPort: json['last_port'] as int?,
    introducedBy: json['introduced_by'] as String?,
  );

  final String id;
  final String name;
  final Platform platform;
  final FormFactor formFactor;
  final Uint8List publicKey;
  final DateTime pairedAt;
  final DateTime? lastSeen;
  final String? lastHost;
  final int? lastPort;

  /// The id of the paired device that vouched for this one, when it joined
  /// through another of the user's devices instead of being paired here.
  final String? introducedBy;

  TrustedDevice copyWith({
    String? name,
    Platform? platform,
    FormFactor? formFactor,
    DateTime? lastSeen,
    String? lastHost,
    int? lastPort,
  }) => TrustedDevice(
    id: id,
    name: name ?? this.name,
    platform: platform ?? this.platform,
    formFactor: formFactor ?? this.formFactor,
    publicKey: publicKey,
    pairedAt: pairedAt,
    lastSeen: lastSeen ?? this.lastSeen,
    lastHost: lastHost ?? this.lastHost,
    lastPort: lastPort ?? this.lastPort,
    introducedBy: introducedBy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform.value,
    'form_factor': formFactor.value,
    'public_key': base64Encode(publicKey),
    'paired_at': pairedAt.millisecondsSinceEpoch,
    'last_seen': ?lastSeen?.millisecondsSinceEpoch,
    'last_host': ?lastHost,
    'last_port': ?lastPort,
    'introduced_by': ?introducedBy,
  };
}
