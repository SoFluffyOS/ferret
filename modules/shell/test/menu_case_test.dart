import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

void main() {
  String on(TargetPlatform platform, String label, {String language = 'en'}) =>
      MenuCase.of(label, languageCode: language, platform: platform);

  test('a Mac keeps title case', () {
    expect(on(.macOS, 'Fix Connection…'), 'Fix Connection…');
  });

  test('Windows and Linux write menus as sentences', () {
    expect(on(.windows, 'Fix Connection…'), 'Fix connection…');
    expect(on(.linux, 'Forget This Device…'), 'Forget this device…');
    expect(on(.linux, 'Show Activity Pane'), 'Show activity pane');
    expect(on(.windows, 'Check My Network…'), 'Check my network…');
    expect(on(.android, 'Pin to Top'), 'Pin to top');
  });

  test('names stay as they are', () {
    expect(
      on(.linux, 'Take Photo with Pixel Tablet'),
      'Take photo with Pixel Tablet',
    );
    expect(on(.windows, 'Sponsor Ferret…'), 'Sponsor Ferret…');
    expect(on(.windows, 'Quit Ferret'), 'Quit Ferret');
  });

  test('other languages are left alone', () {
    expect(on(.windows, 'Sửa Kết Nối', language: 'vi'), 'Sửa Kết Nối');
  });
}
