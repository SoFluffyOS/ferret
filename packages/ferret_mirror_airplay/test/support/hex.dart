import 'dart:typed_data';

Uint8List unhex(String hex) {
  final clean = hex.replaceAll(RegExp(r'\s'), '');
  return Uint8List.fromList([
    for (var index = 0; index < clean.length; index += 2)
      int.parse(clean.substring(index, index + 2), radix: 16),
  ]);
}

String hex(List<int> bytes) => [
  for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
].join();
