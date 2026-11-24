@TestOn('mac-os || linux')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ferret_drop/ferret_drop.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32);
typedef _OpenDart = int Function(Pointer<Utf8>, int);

/// `open(path, O_RDWR)` on a file that is there, for a descriptor like the
/// one Android hands out for a pending download.
int _openForWriting(File file) {
  if (!file.existsSync()) {
    file.createSync();
  }

  final open = DynamicLibrary.process().lookupFunction<_OpenNative, _OpenDart>(
    'open',
  );
  final nativePath = file.path.toNativeUtf8();
  try {
    return open(nativePath, 2);
  } finally {
    calloc.free(nativePath);
  }
}

void main() {
  late Directory folder;
  late File file;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('ferret_descriptor');
    file = File('${folder.path}/clip.mov');
  });

  tearDown(() => folder.delete(recursive: true));

  test('writes go one after the other from the first byte', () async {
    final writer = DescriptorWriter(_openForWriting(file));

    await writer.write([1, 2, 3]);
    await writer.write(List<int>.generate(300000, (index) => index % 251));
    await writer.close();

    final bytes = await file.readAsBytes();
    expect(bytes.length, 300003);
    expect(bytes.take(4), [1, 2, 3, 0]);
    expect(bytes.last, 299999 % 251);
  });

  test('cutting back drops the end and writes after the cut', () async {
    await file.writeAsBytes([1, 2, 3, 4, 5, 6]);
    final writer = DescriptorWriter(_openForWriting(file))..cutTo(4);

    await writer.write([9, 9]);
    await writer.close();

    expect(await file.readAsBytes(), [1, 2, 3, 4, 9, 9]);
  });

  test('a closed writer refuses more bytes', () async {
    final writer = DescriptorWriter(_openForWriting(file));
    await writer.close();

    expect(() => writer.write([1]), throwsA(isA<FileSystemException>()));
  });
}
