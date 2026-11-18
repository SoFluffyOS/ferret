import 'package:flutter_test/flutter_test.dart';
import 'package:remote_input/remote_input.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = RemoteInputFeatureUi();

    expect(ui.featureId, RemoteInputFeature.featureId);
    expect(ui.feature.id, RemoteInputFeature.featureId);
  });
}
