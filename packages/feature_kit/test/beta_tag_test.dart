import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  test('a feature in beta says so where only words fit', () {
    for (final feature in BetaFeature.values) {
      expect(
        feature.label('Use as display', (text) => '$text (beta)'),
        switch (feature.isBeta) {
          true => 'Use as display (beta)',
          false => 'Use as display',
        },
      );
    }
  });

  testWidgets('the tag is read out as its word', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: FluffyTheme(
          data: FluffyThemeData.fallback(brightness: .light),
          child: const Center(
            child: BetaTag(
              .secondDisplay,
              label: 'Beta',
              tooltip: 'Works in our tests',
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Beta'),
      switch (BetaFeature.secondDisplay.isBeta) {
        true => findsOneWidget,
        false => findsNothing,
      },
    );
    semantics.dispose();
  });
}
