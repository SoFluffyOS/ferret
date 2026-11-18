import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:interop_quickshare/interop_quickshare.dart';

/// Short waits, so tests about silence and hanging up stay fast.
const fastTimeouts = QuickShareTimeouts(
  handshake: Duration(seconds: 5),
  idle: Duration(seconds: 5),
  keepAlive: Duration(milliseconds: 200),
  closeGrace: Duration(milliseconds: 200),
);

Uint8List randomBytes(int size, {int seed = 7}) {
  final random = Random(seed);
  return Uint8List.fromList([
    for (var index = 0; index < size; index++) random.nextInt(256),
  ]);
}

Uint8List hex(String digits) => Uint8List.fromList([
  for (var index = 0; index < digits.length; index += 2)
    int.parse(digits.substring(index, index + 2), radix: 16),
]);

String toHex(List<int> bytes) => [
  for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
].join();

/// An outgoing file with [bytes] as its content, read in small pieces.
QuickShareOutgoingFile outgoing(
  String name,
  List<int> bytes, {
  String mimeType = 'application/octet-stream',
  int pieceSize = 16 * 1024,
}) => QuickShareOutgoingFile(
  name: name,
  size: bytes.length,
  mimeType: mimeType,
  open: () => Stream.fromIterable([
    for (var start = 0; start < bytes.length; start += pieceSize)
      bytes.sublist(start, min(start + pieceSize, bytes.length)),
  ]),
);

/// An outgoing file that yields [first], then waits for [gate] before
/// the [rest], so a test can act in the middle of a transfer.
QuickShareOutgoingFile gated(
  String name,
  List<int> first,
  List<int> rest,
  Future<void> gate,
) => QuickShareOutgoingFile(
  name: name,
  size: first.length + rest.length,
  open: () async* {
    yield first;
    await gate;
    yield rest;
  },
);

QuickShareSendJob jobFor(
  QuickShareServer server, {
  List<QuickShareOutgoingFile> files = const [],
  String? text,
  void Function(String pin)? onPin,
  void Function(int sentBytes)? onProgress,
  String name = 'Pixel',
  int chunkSize = 8 * 1024,
}) => QuickShareSendJob(
  address: InternetAddress.loopbackIPv4,
  port: server.boundPort ?? 0,
  sender: QuickShareEndpointInfo(name: name, kind: .phone),
  files: files,
  text: text,
  chunkSize: chunkSize,
  timeouts: fastTimeouts,
  onPin: onPin,
  onProgress: onProgress,
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
