import 'dart:ffi';

import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter_test/flutter_test.dart';

UpdateRelease _release(List<String> names) => UpdateRelease(
  tag: 'v0.2.0',
  notes: '',
  assets: [
    for (final name in names)
      UpdateAsset(
        name: name,
        downloadUrl: Uri.parse('https://example.org/$name'),
      ),
  ],
);

void main() {
  final release = _release([
    'Ferret-0.2.0.dmg',
    'Ferret-mac.dmg',
    'Ferret-0.2.0-x64-setup.exe',
    'Ferret-windows-x64-setup.exe',
    'Ferret-windows-arm64-setup.exe',
    'Ferret-linux-x86_64.AppImage',
    'Ferret-linux-aarch64.AppImage',
    'ferret_0.2.0_amd64.deb',
    'Ferret-android.apk',
    'SHA256SUMS',
  ]);

  test('picks the stable name for each system', () {
    expect(
      UpdateTarget.forAbi(.macosArm64)?.assetIn(release)?.name,
      'Ferret-mac.dmg',
    );
    expect(
      UpdateTarget.forAbi(.macosX64)?.assetIn(release)?.name,
      'Ferret-mac.dmg',
    );
    expect(
      UpdateTarget.forAbi(.windowsX64)?.assetIn(release)?.name,
      'Ferret-windows-x64-setup.exe',
    );
    expect(
      UpdateTarget.forAbi(.windowsArm64)?.assetIn(release)?.name,
      'Ferret-windows-arm64-setup.exe',
    );
    expect(
      UpdateTarget.forAbi(.linuxX64)?.assetIn(release)?.name,
      'Ferret-linux-x86_64.AppImage',
    );
    expect(
      UpdateTarget.forAbi(.linuxArm64)?.assetIn(release)?.name,
      'Ferret-linux-aarch64.AppImage',
    );
    expect(
      UpdateTarget.forAbi(.androidArm64)?.assetIn(release)?.name,
      'Ferret-android.apk',
    );
  });

  test('has nothing for iPhone or a release without the file', () {
    expect(UpdateTarget.forAbi(Abi.iosArm64), isNull);
    expect(UpdateTarget.mac.assetIn(_release(['Ferret-0.2.0.dmg'])), isNull);
  });
}
