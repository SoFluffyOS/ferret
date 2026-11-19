import 'package:flutter_test/flutter_test.dart';
import 'package:phone_camera/phone_camera.dart';

import 'helpers/test_app.dart';

void main() {
  final asked = CaptureAsk(
    requestId: 'r1',
    deviceId: 'mac',
    kind: .photo,
    receivedAt: DateTime(2026, 11, 19),
  );

  Future<(List<String>, List<String>)> pumpCard(
    WidgetTester tester,
    CaptureAsk ask,
  ) async {
    final taken = <String>[];
    final declined = <String>[];
    await tester.pumpWidget(
      testApp(
        CaptureAskCard(
          ask: ask,
          deviceName: 'MacBook Air',
          onTake: () => taken.add(ask.requestId),
          onDecline: () => declined.add(ask.requestId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (taken, declined);
  }

  testWidgets('asks with Take photo and Not now', (tester) async {
    final (taken, declined) = await pumpCard(tester, asked);

    expect(find.text('MacBook Air wants a photo'), findsOneWidget);
    expect(
      find.text('Nothing is taken until you press the shutter.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Take photo'));
    await tester.tap(find.text('Not now'));
    expect(taken, ['r1']);
    expect(declined, ['r1']);
  });

  testWidgets('a scan asks to Scan', (tester) async {
    await pumpCard(
      tester,
      CaptureAsk(
        requestId: 'r2',
        deviceId: 'mac',
        kind: .document,
        receivedAt: DateTime(2026, 11, 19),
      ),
    );

    expect(find.text('MacBook Air wants a document scan'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('while the camera is open the buttons rest', (tester) async {
    final (taken, declined) = await pumpCard(tester, asked.capturing());

    expect(find.text('The camera is open.'), findsOneWidget);
    await tester.tap(find.text('Take photo'), warnIfMissed: false);
    await tester.tap(find.text('Not now'), warnIfMissed: false);
    expect(taken, isEmpty);
    expect(declined, isEmpty);
  });
}
