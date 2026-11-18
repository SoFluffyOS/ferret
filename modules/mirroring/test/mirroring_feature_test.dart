import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = MirroringFeatureUi();

    expect(ui.featureId, MirroringFeature.featureId);
    expect(ui.feature.id, MirroringFeature.featureId);
  });
}
