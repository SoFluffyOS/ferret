import 'dart:convert';
import 'dart:typed_data';

import 'package:protocol/protocol.dart';

/// A device the user paired with.
class TrustedDevice {
  const TrustedDevice({
    required this.id,
    required String name,
    required this.platform,
    required this.formFactor,
    required this.publicKey,
    required this.pairedAt,
    this.lastSeen,
    this.lastHost,
    this.lastPort,
    this.introducedBy,
    this.nickname,
    this.sameNameTag,
    this.wake,
  }) : ownName = name;

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
    nickname: json['nickname'] as String?,
    wake: switch (json['wake']) {
      final String encoded => WakeInfo.fromBuffer(base64Decode(encoded)),
      _ => null,
    },
  );

  final String id;

  /// What the device calls itself, as its owner set it. This is what other
  /// devices are told; [name] is what this one shows.
  final String ownName;

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

  /// A name the user gave it on this device only, such as "Work iPhone".
  /// Never sent to other devices.
  final String? nickname;

  /// The end of its id, set by the trust store while another paired device
  /// without a nickname has the same [ownName], so two "Pixel 7" read as
  /// "Pixel 7 (0718)" and "Pixel 7 (3F2A)". Never stored.
  final String? sameNameTag;

  /// How to wake it from sleep, as it last told this device: its network
  /// cards' MAC and broadcast addresses. Only computers share it, and only
  /// with their paired devices.
  final WakeInfo? wake;

  /// What to call it on screen: the user's nickname, else its own name,
  /// told apart from a namesake by the end of its id.
  String get name {
    if (nickname case final nickname?) {
      return nickname;
    }

    return switch (sameNameTag) {
      final tag? => '$ownName ($tag)',
      null => ownName,
    };
  }

  TrustedDevice copyWith({
    String? name,
    Platform? platform,
    FormFactor? formFactor,
    DateTime? lastSeen,
    String? lastHost,
    int? lastPort,
    WakeInfo? wake,
  }) => TrustedDevice(
    id: id,
    name: name ?? ownName,
    platform: platform ?? this.platform,
    formFactor: formFactor ?? this.formFactor,
    publicKey: publicKey,
    pairedAt: pairedAt,
    lastSeen: lastSeen ?? this.lastSeen,
    lastHost: lastHost ?? this.lastHost,
    lastPort: lastPort ?? this.lastPort,
    introducedBy: introducedBy,
    nickname: nickname,
    wake: wake ?? this.wake,
  );

  /// The same device with [nickname] as its name here, or its own name
  /// again when [nickname] is null or blank.
  TrustedDevice withNickname(String? nickname) => TrustedDevice(
    id: id,
    name: ownName,
    platform: platform,
    formFactor: formFactor,
    publicKey: publicKey,
    pairedAt: pairedAt,
    lastSeen: lastSeen,
    lastHost: lastHost,
    lastPort: lastPort,
    introducedBy: introducedBy,
    nickname: switch (nickname?.trim()) {
      final trimmed? when trimmed.isNotEmpty && trimmed != ownName => trimmed,
      _ => null,
    },
    wake: wake,
  );

  /// The same device told apart from a namesake by [tag].
  TrustedDevice withSameNameTag(String? tag) => TrustedDevice(
    id: id,
    name: ownName,
    platform: platform,
    formFactor: formFactor,
    publicKey: publicKey,
    pairedAt: pairedAt,
    lastSeen: lastSeen,
    lastHost: lastHost,
    lastPort: lastPort,
    introducedBy: introducedBy,
    nickname: nickname,
    sameNameTag: tag,
    wake: wake,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': ownName,
    'platform': platform.value,
    'form_factor': formFactor.value,
    'public_key': base64Encode(publicKey),
    'paired_at': pairedAt.millisecondsSinceEpoch,
    'last_seen': ?lastSeen?.millisecondsSinceEpoch,
    'last_host': ?lastHost,
    'last_port': ?lastPort,
    'introduced_by': ?introducedBy,
    'nickname': ?nickname,
    if (wake case final wake?) 'wake': base64Encode(wake.writeToBuffer()),
  };
}
