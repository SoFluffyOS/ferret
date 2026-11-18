import 'package:find/find.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = FindFeatureUi();

    expect(ui.featureId, FindFeature.featureId);
    expect(ui.feature.id, FindFeature.featureId);
  });
}
