import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

FeatureAction _action(
  String label, {
  int? homeOrder,
  String? sectionId,
  VoidCallback? onPressed,
}) => FeatureAction(
  label: label,
  icon: LucideIcons.circle,
  onPressed: onPressed ?? () {},
  homeOrder: homeOrder,
  sectionId: sectionId,
);

void main() {
  test('actions follow Home\'s order, then the order they came in', () {
    final ordered = DeviceActionOrder.of([
      _action('Call…', sectionId: 'calls'),
      _action('Send clipboard', homeOrder: 20),
      _action('Send a link…'),
      _action('Send files', homeOrder: 10),
    ]);

    expect(
      [for (final action in ordered) action.label],
      ['Send files', 'Send clipboard', 'Call…', 'Send a link…'],
    );
  });

  test('a shortcut to a section the device list shows is left out', () {
    final ordered = DeviceActionOrder.of(
      [
        _action('Messages', sectionId: 'messages'),
        _action('Call…', sectionId: 'calls'),
        _action('Ring', homeOrder: 30),
      ],
      listedSections: {'messages', 'files'},
    );

    expect([for (final action in ordered) action.label], ['Ring', 'Call…']);
  });

  group('DeviceActions', () {
    Widget host(List<FeatureAction> actions, {int shown = 3}) => testApp(
      Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Align(
              alignment: .topLeft,
              child: DeviceActions(
                actions: actions,
                moreLabel: 'More',
                shown: shown,
              ),
            ),
          ),
        ],
      ),
    );

    testWidgets('the first few are buttons, the rest wait behind More', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host([
          for (final label in ['Send files', 'Show screen', 'Ring', 'A', 'B'])
            _action(label, onPressed: () => picked.add(label)),
        ]),
      );

      expect(find.widgetWithText(Button, 'Send files'), findsOneWidget);
      expect(find.widgetWithText(Button, 'Ring'), findsOneWidget);
      expect(find.text('A'), findsNothing);
      expect(
        tester
            .widgetList<Button>(find.byType(Button))
            .where((button) => button.variant == ButtonVariant.primary),
        hasLength(1),
      );

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(picked, ['B']);
    });

    testWidgets('one action too many is a button, not a menu of one', (
      tester,
    ) async {
      await tester.pumpWidget(
        host([
          for (final label in ['One', 'Two', 'Three', 'Four']) _action(label),
        ]),
      );

      expect(find.text('Four'), findsOneWidget);
      expect(find.byType(MenuButton), findsNothing);
    });
  });

  group('TwoColumns', () {
    Widget host(double width) => testApp(
      Align(
        alignment: .topLeft,
        child: SizedBox(
          width: width,
          child: const TwoColumns(
            leading: [Text('What works')],
            trailing: [Text('Pixel may')],
          ),
        ),
      ),
    );

    testWidgets('side by side with room, stacked without', (tester) async {
      await tester.pumpWidget(host(700));
      final wideLeading = tester.getTopLeft(find.text('What works'));
      final wideTrailing = tester.getTopLeft(find.text('Pixel may'));
      expect(wideTrailing.dy, wideLeading.dy);
      expect(wideTrailing.dx, greaterThan(340));

      await tester.pumpWidget(host(500));
      final leading = tester.getTopLeft(find.text('What works'));
      final trailing = tester.getTopLeft(find.text('Pixel may'));
      expect(trailing.dx, leading.dx);
      expect(trailing.dy, greaterThan(leading.dy));
    });
  });
}
