import 'package:drop/drop.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';
import 'support/transfers.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, Transfer transfer) =>
      tester.pumpWidget(
        testApp(
          TransferTile(
            transfer: transfer,
            title: 'Holiday.mov',
            status: 'Status line',
            actions: const [],
            onDismiss: () {},
            dismissLabel: 'Dismiss',
          ),
        ),
      );

  testWidgets('a finished transfer is spoken; megabytes going by are not', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpTile(tester, sampleTransfer(bytesDone: 1024));
    expect(
      tester.getSemantics(find.text('Status line')),
      isNot(isSemantics(label: 'Status line', isLiveRegion: true)),
    );

    await pumpTile(tester, sampleTransfer(status: .done));
    expect(
      tester.getSemantics(find.text('Status line')),
      isSemantics(label: 'Status line', isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('the dismiss cross is a named button a pointer can hit', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpTile(tester, sampleTransfer(status: .done));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Dismiss')),
      isSemantics(
        label: 'Dismiss',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await expectLater(
      tester,
      meetsGuideline(
        const MinimumTapTargetGuideline(
          size: Size(24, 24),
          link:
              'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
