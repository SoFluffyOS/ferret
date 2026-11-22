import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads tags with and without v, ignoring build numbers', () {
    expect(ReleaseVersion.tryParse('v0.2.0')?.numbers, [0, 2, 0]);
    expect(ReleaseVersion.tryParse('0.2.0+7')?.numbers, [0, 2, 0]);
    expect(ReleaseVersion.tryParse('0.3.0-beta.1')?.preRelease, [
      'beta',
      '1',
    ]);
    expect(ReleaseVersion.tryParse('nightly'), isNull);
  });

  test('orders numbers part by part', () {
    expect(isNewerVersion('v0.10.0', '0.9.2'), isTrue);
    expect(isNewerVersion('0.2.0', '0.2.0'), isFalse);
    expect(isNewerVersion('0.2', '0.2.0'), isFalse);
    expect(isNewerVersion('0.1.9', '0.2.0'), isFalse);
    expect(isNewerVersion('1.0.1', '1.0'), isTrue);
  });

  test('puts a test version before its release', () {
    expect(isNewerVersion('0.3.0-beta.1', '0.2.0'), isTrue);
    expect(isNewerVersion('0.3.0-beta.1', '0.3.0'), isFalse);
    expect(isNewerVersion('0.3.0', '0.3.0-beta.2'), isTrue);
    expect(isNewerVersion('0.3.0-beta.10', '0.3.0-beta.2'), isTrue);
    expect(isNewerVersion('0.3.0-rc.1', '0.3.0-beta.9'), isTrue);
  });

  test('never calls an unreadable version newer', () {
    expect(isNewerVersion('latest', '0.1.0'), isFalse);
    expect(isNewerVersion('0.2.0', ''), isFalse);
  });
}
