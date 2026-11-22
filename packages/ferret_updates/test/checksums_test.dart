import 'dart:io';

import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter_test/flutter_test.dart';

const _mac = 'a3f1c2d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
const _apk = 'B3F1C2D4E5F60718293A4B5C6D7E8F90A1B2C3D4E5F60718293A4B5C6D7E8F90';

void main() {
  test('reads shasum and sha256sum lines', () {
    final sums = Checksums.parse(
      '$_mac  Ferret-mac.dmg\n'
      '$_apk *Ferret-android.apk\r\n'
      'not a line\n'
      '\n'
      '$_mac  build/android-packages/Ferret-0.2.0.apk\n',
    );

    expect(sums['Ferret-mac.dmg'], _mac);
    expect(sums['Ferret-android.apk'], _apk.toLowerCase());
    expect(sums['Ferret-0.2.0.apk'], _mac);
    expect(sums['Ferret-windows-x64-setup.exe'], isNull);
  });

  test('hashes a file', () async {
    final folder = await Directory.systemTemp.createTemp('sums');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/abc')..writeAsStringSync('abc');

    expect(
      await Checksums.sha256Of(file.path),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
