import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = NotificationsFeatureUi();

    expect(ui.featureId, NotificationsFeature.featureId);
    expect(ui.feature.id, NotificationsFeature.featureId);
  });
}
