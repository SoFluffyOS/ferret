import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

void main() {
  test('a camera turned off for Ferret is told apart from one that failed', () {
    expect(
      ScanPage.isCameraOff(
        Exception('CameraException(CameraAccessDenied, User denied)'),
      ),
      isTrue,
    );
    expect(
      ScanPage.isCameraOff(
        Exception('CameraException(CameraAccessDeniedWithoutPrompt, …)'),
      ),
      isTrue,
    );
    expect(ScanPage.isCameraOff(Exception('MissingPluginException')), isFalse);
    expect(ScanPage.isCameraOff(null), isFalse);
  });

  testWidgets('with the camera off, the page says so and opens Settings', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const ScanPage(cameraOff: true)));
    await tester.pump();

    expect(find.textContaining("Ferret can't use the camera"), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });
}
