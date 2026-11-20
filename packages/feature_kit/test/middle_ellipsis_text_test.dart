import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontSize: 10);
  const name = 'PXL_20261119_093512345.NIGHT.from-the-team-wiki-export.jpg';

  test('keeps text that fits as it is', () {
    expect(
      MiddleEllipsisText.fit('IMG_2041.jpg', maxWidth: 500, style: style),
      'IMG_2041.jpg',
    );
  });

  test('keeps the start and the end of a long name', () {
    final shown = MiddleEllipsisText.fit(name, maxWidth: 200, style: style);

    expect(shown, contains('…'));
    expect(shown, startsWith('PXL_'));
    expect(shown, endsWith('.jpg'));
    expect(shown.length, greaterThan(10));
  });

  testWidgets('shows the whole text where it fits', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: .ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            child: MiddleEllipsisText(name, style: style),
          ),
        ),
      ),
    );
    expect(find.text(name), findsOneWidget);
  });
}
