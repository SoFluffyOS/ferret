import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

void main() {
  final tapped = <String>[];

  Widget line(String label, {String? button}) => Tappable(
    onTap: () => tapped.add(label),
    child: SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (button != null)
            Tappable(onTap: () => tapped.add(button), child: Text(button)),
        ],
      ),
    ),
  );

  Future<void> show(WidgetTester tester) => tester.pumpWidget(
    testApp(
      Column(
        children: [
          Tappable(onTap: () {}, child: const Text('Above')),
          ArrowKeyStops(
            child: Column(
              children: [
                line('One'),
                line('Two', button: 'Fix'),
                line('Three'),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  String? focused(WidgetTester tester) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      return null;
    }

    final texts = find.descendant(
      of: find.byElementPredicate((element) => element == context),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(texts.first).data;
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
  }

  setUp(tapped.clear);

  testWidgets('↓ and ↑ move a line at a time and skip the buttons inside', (
    tester,
  ) async {
    await show(tester);
    await press(tester, LogicalKeyboardKey.tab);
    await press(tester, LogicalKeyboardKey.tab);
    expect(focused(tester), 'One');

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester), 'Two');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester), 'Three');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester), 'Three', reason: 'the list ends here');

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(focused(tester), 'Two');
    await press(tester, LogicalKeyboardKey.home);
    expect(focused(tester), 'One');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(focused(tester), 'One', reason: 'and starts here');
    await press(tester, LogicalKeyboardKey.end);
    expect(focused(tester), 'Three');
  });

  testWidgets('Tab still reaches a button inside a line, and ↓ goes on from '
      'it', (tester) async {
    await show(tester);
    for (var stop = 0; stop < 4; stop++) {
      await press(tester, LogicalKeyboardKey.tab);
    }
    expect(focused(tester), 'Fix');

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester), 'Three');
  });

  testWidgets('a field among the lines keeps Home, End and ↑, and ↓ goes on '
      'from it', (tester) async {
    final typed = TextEditingController(text: 'pix');
    final field = FocusNode();
    addTearDown(typed.dispose);
    addTearDown(field.dispose);
    await tester.pumpWidget(
      testApp(
        ArrowKeyStops(
          child: Column(
            children: [
              line('One'),
              SizedBox(
                height: 32,
                child: EditableText(
                  controller: typed,
                  focusNode: field,
                  style: const TextStyle(fontSize: 14),
                  cursorColor: const Color(0xFF000000),
                  backgroundCursorColor: const Color(0xFF000000),
                ),
              ),
              line('Three'),
            ],
          ),
        ),
      ),
    );
    field.requestFocus();
    await tester.pump();
    bool isTyping() => field.hasPrimaryFocus;
    expect(isTyping(), isTrue);

    await press(tester, LogicalKeyboardKey.home);
    await press(tester, LogicalKeyboardKey.end);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(isTyping(), isTrue);

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester), 'Three');
  });
}
