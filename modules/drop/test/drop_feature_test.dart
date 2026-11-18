import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = DropFeatureUi();

    expect(ui.featureId, DropFeature.featureId);
    expect(ui.feature.id, DropFeature.featureId);
    expect(ui.feature.flags, containsAll(['send', 'receive']));
  });

  test('every notice category is prefixed with the feature id', () {
    final ui = DropFeatureUi();

    for (final category in ui.noticeCategories) {
      expect(category.id, startsWith('${DropFeature.featureId}.'));
    }
  });
}
