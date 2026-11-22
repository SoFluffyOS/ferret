import 'dart:async';
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
      unawaited(hasher.add(index, offset, bytes.sublist(offset, end)));
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
    unawaited(hasher.add(0, 0, [9, 9, 9]));
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

  test('waits while too much is still to be hashed, then goes on', () async {
    final small = PartHasher(maxBacklog: 4000);
    addTearDown(small.dispose);
    final big = Uint8List.fromList(List.generate(20000, (i) => i * 7 % 256));

    var first = false;
    unawaited(small.add(0, 0, big.sublist(0, 3000)).then((_) => first = true));
    var second = false;
    final waiting = small
        .add(0, 3000, big.sublist(3000, 20000))
        .then((_) => second = true);
    await Future<void>.delayed(Duration.zero);
    expect(first, isTrue);
    expect(second, isFalse);
    expect(small.backlog, greaterThan(4000));

    await waiting;
    expect(small.backlog, lessThanOrEqualTo(2000));
    expect(await small.digest(0, 20000), sha(big));
  });

  test('dispose lets a waiting add go', () async {
    final small = PartHasher(maxBacklog: 10);
    final waiting = small.add(0, 0, bytes);
    small.dispose();
    await waiting;
    expect(small.backlog, 0);
  });
}
