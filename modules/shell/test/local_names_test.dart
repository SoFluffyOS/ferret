import 'dart:ui';

import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/l10n/l10n.dart';

void main() {
  final en = lookupShellLocalizations(const Locale('en'));
  final vi = lookupShellLocalizations(const Locale('vi'));

  LocalDevice device(Platform platform, FormFactor formFactor) =>
      LocalDevice(name: 'Here', platform: platform, formFactor: formFactor);

  test('each kind of device has its own word', () {
    expect(
      en.here(device(.PLATFORM_MACOS, .FORM_FACTOR_LAPTOP)),
      LocalNames.hereMac,
    );
    expect(
      en.here(device(.PLATFORM_ANDROID, .FORM_FACTOR_PHONE)),
      LocalNames.herePhone,
    );
    expect(
      en.here(device(.PLATFORM_ANDROID, .FORM_FACTOR_TABLET)),
      LocalNames.hereTablet,
    );
    expect(
      en.here(device(.PLATFORM_IOS, .FORM_FACTOR_UNSPECIFIED)),
      LocalNames.herePhone,
    );
    expect(
      en.here(device(.PLATFORM_WINDOWS, .FORM_FACTOR_DESKTOP)),
      LocalNames.hereComputer,
    );
  });

  test('a sentence spells this device itself, small inside it', () {
    expect(en.deviceRenameTitle(LocalNames.hereMac), 'Name on this Mac');
    expect(en.deviceRenameTitle(LocalNames.herePhone), 'Name on this phone');
    expect(en.deviceRenameTitle(LocalNames.hereTablet), 'Name on this tablet');
    expect(
      en.deviceRenameTitle(LocalNames.hereComputer),
      'Name on this computer',
    );
    expect(
      en.devicesStaleConfirm('iPad', LocalNames.hereMac),
      'Remove iPad from this Mac?',
    );
  });

  test('and with a capital where it starts one', () {
    expect(
      en.doctorNetworkOk(LocalNames.herePhone),
      'This phone is on Wi-Fi',
    );
    expect(
      en.doctorIsolated('Pixel 7', LocalNames.hereComputer),
      startsWith(
        "This Wi-Fi keeps devices apart, so this computer can't reach Pixel 7",
      ),
    );
  });

  test('the Vietnamese does the same', () {
    expect(
      vi.deviceRenameTitle(LocalNames.herePhone),
      'Tên trên điện thoại này',
    );
    expect(
      vi.doctorNetworkOk(LocalNames.herePhone),
      'Điện thoại này đang có Wi-Fi',
    );
    expect(vi.deviceRenameTitle(LocalNames.hereMac), 'Tên trên Mac này');
  });
}
