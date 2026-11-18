import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = IphoneFeatureUi();

    expect(ui.featureId, IphoneFeature.featureId);
    expect(ui.feature.id, IphoneFeature.featureId);
  });
}
