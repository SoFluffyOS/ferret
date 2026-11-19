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
}
