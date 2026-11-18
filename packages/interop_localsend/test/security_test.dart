import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:test/test.dart';

void main() {
  late LocalSendIdentity identity;

  setUpAll(() async {
    identity = await LocalSendIdentity.generate();
  });

  test('the fingerprint is the SHA-256 of the certificate', () {
    final der = Pem.decode(identity.certificatePem);

    expect(der, isNotNull);
    expect(identity.fingerprint, sha256.convert(der ?? const []).toString());
    expect(identity.fingerprint, hasLength(64));
  });

  test('an identity survives being stored', () {
    final restored = LocalSendIdentity.decode(identity.encode());

    expect(restored?.fingerprint, identity.fingerprint);
    expect(restored?.privateKeyPem, identity.privateKeyPem);
    expect(LocalSendIdentity.decode('not json'), isNull);
    expect(LocalSendIdentity.decode('{"certificate": "x"}'), isNull);
  });

  test('every identity is different', () async {
    final other = await LocalSendIdentity.generate();

    expect(other.fingerprint, isNot(identity.fingerprint));
  });

  test('TLS accepts the certificate, and the peer sees the same one', () async {
    final server = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      identity.securityContext(),
    );
    addTearDown(server.close);
    server.listen((socket) => socket.destroy());

    String? seen;
    X509Certificate? presented;
    final socket = await SecureSocket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
      context: SecurityContext(withTrustedRoots: false),
      onBadCertificate: (certificate) {
        presented = certificate;
        seen = Fingerprints.ofCertificate(certificate.der);
        return true;
      },
    );
    socket.destroy();

    expect(seen, identity.fingerprint);
    expect(presented?.subject, contains('Ferret'));
    final end = presented?.endValidity ?? DateTime(2000);
    expect(end.isAfter(DateTime.now().add(const Duration(days: 3000))), isTrue);
  });

  test('fingerprints compare without caring about case', () {
    expect(Fingerprints.same('AB12', 'ab12'), isTrue);
    expect(Fingerprints.same('AB12', 'ab13'), isFalse);
    expect(
      Fingerprints.short('3f2a91bc07de44a1ffffffff'),
      '3F2A 91BC 07DE 44A1',
    );
    expect(Fingerprints.short('abc'), 'ABC');
  });

  test('DER integers and lengths follow the rules', () {
    expect(Der.integer(BigInt.zero), [0x02, 0x01, 0x00]);
    expect(Der.integer(BigInt.from(127)), [0x02, 0x01, 0x7f]);
    expect(Der.integer(BigInt.from(128)), [0x02, 0x02, 0x00, 0x80]);
    expect(Der.oid('1.2.840.113549.1.1.11'), [
      0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x0b, //
    ]);
    expect(Der.octetString(List.filled(200, 1)).sublist(0, 3), [
      0x04, 0x81, 200, //
    ]);
    expect(
      String.fromCharCodes(Der.time(DateTime.utc(2026, 11, 18)).skip(2)),
      '261118000000Z',
    );
    expect(
      String.fromCharCodes(Der.time(DateTime.utc(2051, 1, 2)).skip(2)),
      '20510102000000Z',
    );
  });
}
