import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = MediaFeatureUi();

    expect(ui.featureId, MediaFeature.featureId);
    expect(ui.feature.id, MediaFeature.featureId);
  });
}
