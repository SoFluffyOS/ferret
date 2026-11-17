import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = DropFeatureUi();

    expect(ui.featureId, DropFeature.featureId);
    expect(ui.feature.id, DropFeature.featureId);
  });
}
