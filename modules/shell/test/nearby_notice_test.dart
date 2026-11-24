import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

void main() {
  testWidgets('"Looking…" holds the room of "No devices found yet" with '
      'Look again, so a link below stays put when looking ends', (
    tester,
  ) async {
    final link = GlobalKey();
    Widget page(Widget notice) => testApp(
      Column(
        children: [
          notice,
          Text('Check my network', key: link),
        ],
      ),
    );

    await tester.pumpWidget(
      page(
        const NearbyNotice(
          body: 'Looking for devices…',
          holdsRoomFor: (
            body: 'No devices found yet.',
            actionLabel: 'Look again',
          ),
        ),
      ),
    );
    final whileLooking = tester.getTopLeft(find.byKey(link));
    expect(find.text('Look again').hitTestable(), findsNothing);
    expect(find.bySemanticsLabel('Look again'), findsNothing);

    await tester.pumpWidget(
      page(
        NearbyNotice(
          body: 'No devices found yet.',
          actionLabel: 'Look again',
          onAction: () {},
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(link)), whileLooking);
    expect(find.text('Look again'), findsOneWidget);
  });
}
