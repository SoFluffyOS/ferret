import 'package:calls/calls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = CallsFeatureUi();

    expect(ui.featureId, CallsFeature.featureId);
    expect(ui.feature.id, CallsFeature.featureId);
  });
}
