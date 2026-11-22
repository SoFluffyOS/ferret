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
      FluffyDensityScope(
        density: .pointer,
        child: app(TextLink(label: 'See all', onTap: () => taps++)),
      ),
    );

    final target = tester.getRect(find.byType(TextLink));
    expect(tester.getSize(find.text('See all')).height, lessThan(24));
    expect(target.height, TextLink.minHeight);

    await tester.tapAt(target.topLeft + const Offset(6, 1));
    await tester.tapAt(target.bottomLeft + const Offset(6, -1));
    await tester.tapAt(target.topLeft + const Offset(6, -2));
    expect(taps, 2, reason: 'a mouse gets what the link lays out on');
  });

  testWidgets('a finger gets 48 dp around the words, and the line stays as '
      'high as for a pointer', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(TextLink(label: 'See all', onTap: () => taps++)),
    );

    final line = tester.getRect(find.byType(TextLink));
    expect(line.height, TextLink.minHeight);
    final reach = (Spacing.d48 - line.height) / 2;

    await tester.tapAt(line.topCenter + Offset(0, -reach + 1));
    await tester.tapAt(line.bottomCenter + Offset(0, reach - 1));
    expect(taps, 2, reason: 'taps in the 48 dp around the line land');

    await tester.tapAt(line.topCenter + Offset(0, -reach - 2));
    await tester.tapAt(line.bottomCenter + Offset(0, reach + 2));
    expect(taps, 2, reason: 'and not beyond it');
  });

  testWidgets('words at the top line up with text next to them, and the '
      'target goes on below as far as the row reaches', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saved to Downloads', style: TextStyle(fontSize: 12)),
              TextLink(
                label: 'Open',
                onTap: () => taps++,
                alignment: Alignment.topCenter,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Open')).dy,
      tester.getTopLeft(find.text('Saved to Downloads')).dy,
    );
    final line = tester.getRect(find.byType(TextLink));
    expect(line.height, TextLink.minHeight);

    await tester.tapAt(line.topCenter + Offset(0, Spacing.d48 - 1));
    expect(taps, 1, reason: 'the target reaches 48 dp down');
    await tester.tapAt(line.topCenter + Offset(0, Spacing.d48 + 2));
    await tester.tapAt(line.topCenter + const Offset(0, -2));
    expect(taps, 1, reason: 'and no further, nor above the words');
  });

  testWidgets('a section title is as high with a link as without, and a '
      'finger can tap the link on all of it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(const SectionTitle('Activity')));
    final alone = tester.getSize(find.byType(SectionTitle)).height;
    expect(alone, 40);

    await tester.pumpWidget(
      app(
        SectionTitle(
          'Activity',
          trailing: TextLink(label: 'See all', onTap: () => taps++),
        ),
      ),
    );

    final title = tester.getRect(find.byType(SectionTitle));
    expect(title.height, alone);
    final link = tester.getRect(find.byType(TextLink));
    await tester.tapAt(Offset(link.center.dx, title.top + 1));
    await tester.tapAt(Offset(link.center.dx, title.bottom - 1));
    expect(taps, 2);
  });
}
