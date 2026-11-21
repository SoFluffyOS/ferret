import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

void main() {
  const android = Platform.PLATFORM_ANDROID;
  const iphone = Platform.PLATFORM_IOS;
  const mac = Platform.PLATFORM_MACOS;
  const windows = Platform.PLATFORM_WINDOWS;
  const linux = Platform.PLATFORM_LINUX;

  const shared = [
    'clipboard',
    'drop',
    'handoff',
    'find',
    'scripting',
    'actions',
    'notifications',
    'messages',
    'calls',
    'mirroring',
    'remote_input',
    'media',
    'camera',
    'photos',
    'wake',
  ];

  List<String> listed(Platform here, Platform there) => [
    for (final feature in shared)
      if (FeatureAccess.reaches(feature, here, there)) feature,
  ];

  test('a Mac and an iPhone: no texts, calls, notifications, screen or '
      'wake', () {
    const expected = [
      'clipboard',
      'drop',
      'handoff',
      'find',
      'scripting',
      'actions',
      'remote_input',
      'media',
      'camera',
      'photos',
    ];
    expect(listed(mac, iphone), expected);
    expect(listed(iphone, mac), expected);
  });

  test('a Mac and an Android phone: everything but wake', () {
    final expected = [...shared]..remove('wake');
    expect(listed(mac, android), expected);
    expect(listed(android, mac), expected);
  });

  test('two Macs: no phone features, but screens, input and wake', () {
    expect(listed(mac, mac), [
      'clipboard',
      'drop',
      'handoff',
      'find',
      'scripting',
      'actions',
      'mirroring',
      'remote_input',
      'media',
      'wake',
    ]);
  });

  test('a Windows PC and a Linux PC: no screens or touchpad', () {
    expect(listed(windows, linux), [
      'clipboard',
      'drop',
      'handoff',
      'find',
      'scripting',
      'actions',
      'media',
      'wake',
    ]);
  });

  test('an Android phone and an iPhone: the Android side shares', () {
    expect(listed(android, iphone), [
      'clipboard',
      'drop',
      'handoff',
      'find',
      'scripting',
      'notifications',
      'messages',
      'calls',
      'media',
    ]);
  });

  test('two iPhones share only what both can do', () {
    expect(listed(iphone, iphone), [
      'clipboard',
      'drop',
      'handoff',
      'find',
      'scripting',
    ]);
  });

  test('an unknown platform or feature is always listed', () {
    expect(listed(mac, Platform.PLATFORM_UNSPECIFIED), shared);
    expect(FeatureAccess.reaches('someday', iphone, iphone), isTrue);
  });

  test('a phone offers calls, texts and notifications once a computer is '
      'paired', () {
    const promised = ['notifications', 'messages', 'calls'];
    for (final feature in promised) {
      expect(FeatureAccess.offeredWith(feature, const []), isFalse);
      expect(FeatureAccess.offeredWith(feature, const [iphone]), isFalse);
      expect(FeatureAccess.offeredWith(feature, const [android]), isFalse);
      expect(FeatureAccess.offeredWith(feature, const [iphone, mac]), isTrue);
      expect(FeatureAccess.offeredWith(feature, const [windows]), isTrue);
      expect(FeatureAccess.offeredWith(feature, const [linux]), isTrue);
    }
    expect(FeatureAccess.offeredWith('drop', const [iphone]), isTrue);
    expect(FeatureAccess.offeredWith('clipboard', const []), isTrue);
  });
}
