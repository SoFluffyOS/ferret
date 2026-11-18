import 'package:flutter_test/flutter_test.dart';
import 'package:power/power.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = PowerFeatureUi();

    expect(ui.featureId, PowerFeature.featureId);
    expect(ui.feature.id, PowerFeature.featureId);
  });
}
