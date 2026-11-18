import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:interop_localsend/security/certificate_builder.dart';
import 'package:interop_localsend/security/fingerprints.dart';
import 'package:interop_localsend/security/pem.dart';

/// This device as a LocalSend member: its self-signed certificate, the key
/// for it, and the fingerprint other members know it by.
class LocalSendIdentity {
  const LocalSendIdentity._({
    required this.certificatePem,
    required this.privateKeyPem,
    required this.fingerprint,
  });

  static const _certificateField = 'certificate';
  static const _privateKeyField = 'private_key';

  final String certificatePem;

  /// Keep it in a secret store.
  final String privateKeyPem;

  /// The SHA-256 of the certificate, in hex.
  final String fingerprint;

  /// Makes a new identity in a background isolate.
  static Future<LocalSendIdentity> generate({
    String commonName = 'Ferret',
  }) async {
    final made = await Isolate.run(
      () => CertificateBuilder.selfSigned(commonName: commonName),
    );
    return LocalSendIdentity._(
      certificatePem: Pem.encode(Pem.certificateLabel, made.certificate),
      privateKeyPem: Pem.encode(Pem.privateKeyLabel, made.privateKey),
      fingerprint: Fingerprints.ofCertificate(made.certificate),
    );
  }

  /// Reads what [encode] wrote, or returns null when it is damaged.
  static LocalSendIdentity? decode(String stored) {
    final Object? json;
    try {
      json = jsonDecode(stored);
    } on FormatException {
      return null;
    }

    if (json case {
      _certificateField: final String certificate,
      _privateKeyField: final String privateKey,
    }) {
      final der = Pem.decode(certificate);
      if (der == null || Pem.decode(privateKey) == null) {
        return null;
      }

      return LocalSendIdentity._(
        certificatePem: certificate,
        privateKeyPem: privateKey,
        fingerprint: Fingerprints.ofCertificate(der),
      );
    }

    return null;
  }

  /// The identity as one string, for a secret store.
  String encode() => jsonEncode({
    _certificateField: certificatePem,
    _privateKeyField: privateKeyPem,
  });

  /// A TLS context that presents this identity and trusts no authority:
  /// LocalSend members check fingerprints instead.
  SecurityContext securityContext() => SecurityContext(withTrustedRoots: false)
    ..useCertificateChainBytes(utf8.encode(certificatePem))
    ..usePrivateKeyBytes(utf8.encode(privateKeyPem));
}
