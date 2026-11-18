import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = MessagesFeatureUi();

    expect(ui.featureId, MessagesFeature.featureId);
    expect(ui.feature.id, MessagesFeature.featureId);
  });
}
