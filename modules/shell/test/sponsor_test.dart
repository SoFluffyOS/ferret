import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

void main() {
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final opened = <String>[];

  setUp(() {
    opened.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, (call) async {
          if (call.arguments case {'url': final String url}) {
            opened.add(url);
          }

          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, null);
  });

  test('the sponsor page is the owner\'s GitHub Sponsors page', () {
    expect(Sponsor.page.toString(), 'https://github.com/sponsors/simonpham');
  });

  testWidgets('Sponsor Ferret opens the sponsor page in the browser', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const SponsorRow()));

    expect(find.text('Sponsor Ferret'), findsOneWidget);

    await tester.tap(find.text('Sponsor Ferret'));
    await tester.pumpAndSettle();

    expect(opened, ['https://github.com/sponsors/simonpham']);
  });
}
