import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The updater compares a release's tag with the version `lib/main.dart`
/// passes as `appVersion`; one left behind after a bump would offer the
/// same update again and again.
void main() {
  test('main.dart says the version pubspec.yaml has', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    final appVersion = RegExp(
      r"appVersion:\s*'([^']+)'",
    ).firstMatch(main)?.group(1);

    expect(version, isNotNull);
    expect(appVersion, version);
  });
}
