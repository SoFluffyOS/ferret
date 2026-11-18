import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:interop_localsend/interop_localsend.dart';

LocalSendInfo infoFor(
  LocalSendIdentity identity,
  String alias, {
  int? port,
}) => LocalSendInfo(
  alias: alias,
  fingerprint: identity.fingerprint,
  deviceModel: 'Test',
  deviceType: .desktop,
  port: port,
  protocol: LocalSendDefaults.https,
);

LocalSendPeer peerFor(LocalSendIdentity identity, int port) => LocalSendPeer(
  info: infoFor(identity, 'Receiver', port: port),
  address: InternetAddress.loopbackIPv4,
  lastSeen: DateTime.now(),
);

Uint8List randomBytes(int size, {int seed = 7}) {
  final random = Random(seed);
  return Uint8List.fromList([
    for (var index = 0; index < size; index++) random.nextInt(256),
  ]);
}

/// An outgoing file with [bytes] as its content, sent in small chunks.
LocalSendOutgoingFile outgoing(
  String id,
  String name,
  List<int> bytes, {
  bool withHash = false,
  String? sha256Override,
  int chunkSize = 16 * 1024,
}) => LocalSendOutgoingFile(
  file: LocalSendFile(
    id: id,
    fileName: name,
    size: bytes.length,
    sha256:
        sha256Override ??
        switch (withHash) {
          true => sha256.convert(bytes).toString(),
          false => null,
        },
  ),
  open: () => Stream.fromIterable([
    for (var start = 0; start < bytes.length; start += chunkSize)
      bytes.sublist(start, min(start + chunkSize, bytes.length)),
  ]),
);

/// Waits until [condition] holds, polling briefly.
Future<void> until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Condition not met in $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
