import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = HandoffFeatureUi();

    expect(ui.featureId, HandoffFeature.featureId);
    expect(ui.feature.id, HandoffFeature.featureId);
  });
}
