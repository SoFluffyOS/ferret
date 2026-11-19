import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

void main() {
  testWidgets('How? says which feature it is for', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        const HealthRow(
          title: 'Messages',
          health: FeatureHealth(.off, reason: 'Off on Pixel 9', help: 'Steps'),
          howLabel: 'How?',
          fixLabel: 'Fix',
        ),
      ),
    );

    expect(find.bySemanticsLabel('How? Messages'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets("an Activity line's Open says which line it is on", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        ActivityTextAction(
          action: ActivityAction(label: 'Open', onPressed: () {}),
          filled: false,
          isShown: true,
          subject: 'IMG_2041.jpg from Pixel 9',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Open: IMG_2041.jpg from Pixel 9'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
