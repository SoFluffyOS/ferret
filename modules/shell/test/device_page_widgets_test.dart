import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

Widget _health(FeatureHealth health) => testApp(
  HealthRow(
    title: 'Notifications',
    health: health,
    howLabel: 'How?',
    fixLabel: 'Fix',
  ),
);

FeatureSettings _part(
  SettingsGroup group, {
  bool? isOn,
  bool needsAttention = false,
}) => FeatureSettings(
  group: group,
  title: group.name,
  child: const SizedBox.shrink(),
  isOn: isOn,
  needsAttention: needsAttention,
);

void main() {
  testWidgets('a feature that works shows its fact and nothing to tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _health(const FeatureHealth(.ok, reason: '12 apps', help: 'unused')),
    );

    expect(find.text('12 apps'), findsOneWidget);
    expect(find.text('How?'), findsNothing);
    expect(find.text('Fix'), findsNothing);
  });

  testWidgets('a feature that is off says how to turn it on, in place', (
    tester,
  ) async {
    const steps = 'On Pixel 9: Ferret → Do more → Notifications';
    await tester.pumpWidget(
      _health(
        const FeatureHealth(.off, reason: 'Off on Pixel 9', help: steps),
      ),
    );

    expect(find.text('Off on Pixel 9'), findsOneWidget);
    expect(find.text(steps), findsNothing);

    await tester.tap(find.text('How?'));
    await tester.pump();

    expect(find.text(steps), findsOneWidget);
  });

  testWidgets('a broken feature offers its fix', (tester) async {
    var fixed = false;
    await tester.pumpWidget(
      _health(
        FeatureHealth(
          .needsAttention,
          reason: "Android turned off Ferret's access",
          onFix: () => fixed = true,
        ),
      ),
    );

    await tester.tap(find.text('Fix'));

    expect(fixed, isTrue);
  });

  testWidgets('forgetting asks in place, and a lone pairing has one answer', (
    tester,
  ) async {
    final scopes = <ForgetScope>[];
    await tester.pumpWidget(
      testApp(
        ForgetDeviceCard(
          deviceName: 'Pixel 9',
          here: LocalNames.hereMac,
          sharedWithOthers: false,
          onForget: scopes.add,
        ),
      ),
    );

    await tester.tap(find.text('Forget Pixel 9'));
    await tester.pump();

    expect(find.text('Forget Pixel 9?'), findsOneWidget);
    expect(find.text('Remove everywhere'), findsNothing);

    await tester.tap(find.text('Forget'));

    expect(scopes, [ForgetScope.here]);
  });

  testWidgets('a device the others know can leave them all, or only here', (
    tester,
  ) async {
    final scopes = <ForgetScope>[];
    await tester.pumpWidget(
      testApp(
        ForgetDeviceCard(
          deviceName: 'Pixel 9',
          here: LocalNames.hereMac,
          sharedWithOthers: true,
          onForget: scopes.add,
        ),
      ),
    );

    await tester.tap(find.text('Forget Pixel 9'));
    await tester.pump();
    await tester.tap(find.text('Remove everywhere'));
    await tester.tap(find.text('Forget here only'));

    expect(scopes, [ForgetScope.everywhere, ForgetScope.here]);
  });

  testWidgets('cancel puts the quiet line back', (tester) async {
    await tester.pumpWidget(
      testApp(
        ForgetDeviceCard(
          deviceName: 'Pixel 9',
          here: LocalNames.hereMac,
          sharedWithOthers: true,
          onForget: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Forget Pixel 9'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Forget Pixel 9?'), findsNothing);
    expect(find.text('Forget Pixel 9'), findsOneWidget);
  });

  test('settings rows follow the group order and skip empty groups', () {
    final rows = SettingsRow.from([
      _part(.control, isOn: false),
      _part(.phone, isOn: true),
      _part(.phone, isOn: false),
      _part(.clipboard),
    ]);

    expect(
      [for (final row in rows) row.group],
      [
        SettingsGroup.clipboard,
        SettingsGroup.phone,
        SettingsGroup.control,
      ],
    );
    expect(rows[1].switchable, hasLength(2));
    expect(rows[1].on, hasLength(1));
    expect(rows[0].switchable, isEmpty);
  });

  test('a row asks for attention only when one of its parts does', () {
    final quiet = SettingsRow.from([_part(.files, isOn: false)]).single;
    final failing = SettingsRow.from([
      _part(.files, isOn: true),
      _part(.files, isOn: true, needsAttention: true),
    ]).single;

    expect(quiet.needsAttention, isFalse);
    expect(failing.needsAttention, isTrue);
  });

  testWidgets('a settings row shows its state and a warning dot when asked', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      testApp(
        NavRow(
          title: 'Files',
          value: 'To Downloads',
          attentionLabel: 'Needs attention',
          onTap: () => opened = true,
        ),
      ),
    );

    expect(find.text('To Downloads'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Needs attention',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Files'));

    expect(opened, isTrue);
  });
}
