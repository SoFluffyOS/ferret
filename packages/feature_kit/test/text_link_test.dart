import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  Widget app(Widget child) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );

  testWidgets('small words, a target a pointer can hit', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(TextLink(label: 'See all', onTap: () => taps++)),
    );

    final target = tester.getSize(find.byType(TextLink));
    final words = tester.getSize(find.text('See all'));
    expect(words.height, lessThan(TextLink.minHeight));
    expect(target.height, TextLink.minHeight);

    await tester.tapAt(
      tester.getTopLeft(find.byType(TextLink)) + const Offset(6, 1),
    );
    await tester.tapAt(
      tester.getBottomLeft(find.byType(TextLink)) + const Offset(6, -1),
    );
    expect(taps, 2);
  });

  testWidgets('words at the top line up with text next to them, and the '
      'target goes on below', (tester) async {
    await tester.pumpWidget(
      app(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved to Downloads', style: TextStyle(fontSize: 12)),
            TextLink(
              label: 'Open',
              onTap: () {},
              alignment: Alignment.topCenter,
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Open')).dy,
      tester.getTopLeft(find.text('Saved to Downloads')).dy,
    );
    expect(tester.getSize(find.byType(TextLink)).height, TextLink.minHeight);
  });

  testWidgets('a section title is as high with a link as without', (
    tester,
  ) async {
    await tester.pumpWidget(app(const SectionTitle('Activity')));
    final alone = tester.getSize(find.byType(SectionTitle)).height;

    await tester.pumpWidget(
      app(
        SectionTitle(
          'Activity',
          trailing: TextLink(label: 'See all', onTap: () {}),
        ),
      ),
    );

    expect(tester.getSize(find.byType(SectionTitle)).height, alone);
  });
}
