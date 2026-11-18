import 'package:engine/engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

PairingPrompt _prompt() => PairingPrompt(
  device: DeviceInfo(
    id: 'abcdabcdabcdabcd',
    name: 'Pixel 9',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
  ),
  code: '123456',
  expiresAt: DateTime.now().add(const Duration(minutes: 1)),
);

void main() {
  testWidgets('the pairing code is spoken digit by digit, as it shows up', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(testApp(const ComparisonCode(code: '123456')));
    await tester.pump();

    expect(
      tester.getSemantics(find.byType(ComparisonCode)),
      isSemantics(label: 'Code: 1 2 3 4 5 6', isLiveRegion: true),
    );
    expect(find.bySemanticsLabel('123 456'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a switch row is one stop that says its name and state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final changes = <bool>[];
    await tester.pumpWidget(
      testApp(
        SwitchRow(
          title: 'Open at login',
          subtitle: 'Ferret starts with your computer.',
          value: true,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSemantics(find.byType(SwitchRow)),
      isSemantics(
        label: 'Open at login\nFerret starts with your computer.',
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  group('the pairing request', () {
    Future<PairingPrompt> open(WidgetTester tester) async {
      final prompt = _prompt();
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => GestureDetector(
              behavior: .opaque,
              onTap: () => PairingPromptDialog.show(context, prompt),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return prompt;
    }

    testWidgets('Esc answers Not now', (tester) async {
      final prompt = await open(tester);
      expect(find.text('Pair with Pixel 9?'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pair with Pixel 9?'), findsNothing);
      expect(await prompt.answer, PairingAnswer.rejected);
    });

    testWidgets('Tab reaches Not now, then Pair, and Enter pairs', (
      tester,
    ) async {
      final prompt = await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(await prompt.answer, PairingAnswer.accepted);
    });

    testWidgets('is announced as a dialog, with labelled buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final prompt = await open(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Not now')),
        isSemantics(
          label: 'Not now',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Code: 1 2 3 4 5 6'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      prompt.reject();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      semantics.dispose();
    });
  });
}
