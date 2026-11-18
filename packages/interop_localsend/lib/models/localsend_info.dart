import 'package:interop_localsend/models/json_fields.dart';
import 'package:interop_localsend/models/localsend_constants.dart';
import 'package:interop_localsend/models/localsend_device_type.dart';

/// How a LocalSend member describes itself, in announcements, `/register`,
/// `/info` and `/prepare-upload`.
class LocalSendInfo {
  const LocalSendInfo({
    required this.alias,
    required this.fingerprint,
    this.version = LocalSendDefaults.version,
    this.deviceModel,
    this.deviceType = LocalSendDeviceType.desktop,
    this.port,
    this.protocol,
    this.download = false,
  });

  /// The name people see, such as "Nice Orange".
  final String alias;
  final String version;
  final String? deviceModel;
  final LocalSendDeviceType deviceType;

  /// With HTTPS, the SHA-256 of the member's certificate. With HTTP, a
  /// random string.
  final String fingerprint;

  /// Missing in `/register` and `/info` answers, which come from the port
  /// that was asked.
  final int? port;

  /// `https` or `http`.
  final String? protocol;

  /// Whether the member offers the browser download API.
  final bool download;

  bool get isEncrypted => protocol != LocalSendDefaults.http;

  /// Reads a member's description, or returns null when a required field
  /// is missing or has the wrong type.
  static LocalSendInfo? fromJson(Object? json) {
    final fields = JsonFields.object(json);
    if (fields == null) {
      return null;
    }

    final alias = JsonFields.text(fields['alias'], max: 64);
    final fingerprint = JsonFields.raw(fields['fingerprint'], max: 256);
    if (alias == null || fingerprint == null) {
      return null;
    }

    final port = JsonFields.integer(fields['port']);
    if (port != null && (port < 1 || port > 65535)) {
      return null;
    }

    final protocol = switch (fields['protocol']) {
      LocalSendDefaults.http => LocalSendDefaults.http,
      LocalSendDefaults.https => LocalSendDefaults.https,
      _ => null,
    };
    return LocalSendInfo(
      alias: alias,
      fingerprint: fingerprint,
      version:
          JsonFields.text(fields['version'], max: 16) ??
          LocalSendDefaults.version,
      deviceModel: JsonFields.text(fields['deviceModel'], max: 64),
      deviceType: LocalSendDeviceType.parse(fields['deviceType']),
      port: port,
      protocol: protocol,
      download: fields['download'] == true,
    );
  }

  /// The full description, as sent in `/register` and `/prepare-upload`.
  Map<String, Object?> toJson() => {
    'alias': alias,
    'version': version,
    'deviceModel': deviceModel,
    'deviceType': deviceType.name,
    'fingerprint': fingerprint,
    'port': ?port,
    'protocol': ?protocol,
    'download': download,
  };

  /// The description without port and protocol, as answered by `/register`
  /// and `/info`.
  Map<String, Object?> toAnswerJson() => {
    'alias': alias,
    'version': version,
    'deviceModel': deviceModel,
    'deviceType': deviceType.name,
    'fingerprint': fingerprint,
    'download': download,
  };

  LocalSendInfo copyWith({String? fingerprint, int? port, String? protocol}) =>
      LocalSendInfo(
        alias: alias,
        fingerprint: fingerprint ?? this.fingerprint,
        version: version,
        deviceModel: deviceModel,
        deviceType: deviceType,
        port: port ?? this.port,
        protocol: protocol ?? this.protocol,
        download: download,
      );
}
