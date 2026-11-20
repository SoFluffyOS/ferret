import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drop/services/part_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bytes = Uint8List.fromList(List.generate(10000, (i) => i * 31 % 256));
  List<int> sha(List<int> data) => sha256.convert(data).bytes;

  late PartHasher hasher;
  setUp(() => hasher = PartHasher());
  tearDown(() => hasher.dispose());

  void feed(int index, int from, int to, {int step = 1000}) {
    for (var offset = from; offset < to; offset += step) {
      final end = offset + step > to ? to : offset + step;
      hasher.add(index, offset, bytes.sublist(offset, end));
    }
  }

  test('bytes in order give the file hash, file by file', () async {
    feed(0, 0, 10000);
    feed(1, 0, 4000, step: 333);

    expect(await hasher.digest(0, 10000), sha(bytes));
    expect(await hasher.digest(1, 4000), sha(bytes.sublist(0, 4000)));
  });

  test('a gap or a different length means hash the file on disk', () async {
    feed(0, 0, 3000);
    feed(0, 4000, 6000);
    feed(1, 0, 3000);

    expect(await hasher.digest(0, 6000), isNull);
    expect(await hasher.digest(1, 5000), isNull);
  });

  test('a part cut back for a resume is not trusted', () async {
    feed(0, 0, 5000);
    hasher.forget(0);
    feed(0, 5000, 10000);

    expect(await hasher.digest(0, 10000), isNull);
  });

  test('a part that starts over is hashed again from its start', () async {
    hasher.add(0, 0, [9, 9, 9]);
    hasher.forget(0);
    feed(0, 0, 10000);

    expect(await hasher.digest(0, 10000), sha(bytes));
  });

  test('nothing hashed and after dispose, it answers null', () async {
    expect(await hasher.digest(3, 0), isNull);

    feed(0, 0, 2000);
    final pending = hasher.digest(0, 2000);
    hasher.dispose();
    expect(await pending, anyOf(isNull, sha(bytes.sublist(0, 2000))));
    expect(await hasher.digest(0, 2000), isNull);
  });
}
