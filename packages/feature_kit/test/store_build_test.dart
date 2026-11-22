import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the store a build is made for', () {
    expect(StoreBuild.parse('play'), StoreBuild.play);
    expect(StoreBuild.parse(' Play '), StoreBuild.play);
    expect(StoreBuild.parse(''), StoreBuild.none);
    expect(StoreBuild.parse('github'), StoreBuild.none);
  });

  test('a plain build is no store build', () {
    expect(StoreBuild.current, StoreBuild.none);
  });
}
