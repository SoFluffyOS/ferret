import 'package:clipboard/clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = ClipboardFeatureUi();

    expect(ui.featureId, ClipboardFeature.featureId);
    expect(ui.feature.id, ClipboardFeature.featureId);
  });
}
