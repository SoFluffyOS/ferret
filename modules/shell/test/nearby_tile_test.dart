import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

import 'test_app.dart';

final _pixel = DiscoveredPeer(
  announce: Announce(
    deviceId: 'pixelpixelpixel2',
    name: 'Pixel 7',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    port: 47640,
  ),
  host: '192.168.1.78',
);

void main() {
  testWidgets('a device near you offers one button: Pair', (tester) async {
    var asked = false;

    await tester.pumpWidget(
      testApp(
        NearbyTile(peer: _pixel, isFirst: true, onPair: () => asked = true),
      ),
    );

    expect(find.text('Pixel 7'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    await tester.tap(find.text('Pair'));
    expect(asked, isTrue);
  });

  testWidgets('comparing shows the code and asks whether they match', (
    tester,
  ) async {
    var confirmed = false;
    var cancelled = false;

    await tester.pumpWidget(
      testApp(
        NearbyTile(
          peer: _pixel,
          attempt: NearbyComparing(_pixel, '482913'),
          onPair: () {},
          onConfirm: () => confirmed = true,
          onCancel: () => cancelled = true,
        ),
      ),
    );

    expect(find.text('482 913'), findsOneWidget);
    expect(find.text('Check that Pixel 7 shows this code.'), findsOneWidget);
    expect(find.text('Pair'), findsNothing);
    await tester.tap(find.text('They match'));
    await tester.tap(find.text('Cancel'));
    expect(confirmed, isTrue);
    expect(cancelled, isTrue);
  });

  testWidgets('after confirming it says what to do on the other device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        NearbyTile(
          peer: _pixel,
          attempt: NearbyComparing(_pixel, '482913', confirmedHere: true),
          onPair: () {},
        ),
      ),
    );

    expect(find.text('482 913'), findsOneWidget);
    expect(find.text('On Pixel 7, tap Pair.'), findsOneWidget);
    expect(find.text('Waiting for Pixel 7…'), findsOneWidget);
    expect(find.text('They match'), findsNothing);
  });

  testWidgets('a failure says what happened in plain words, with a way on', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      testApp(
        NearbyTile(
          peer: _pixel,
          attempt: NearbyFailed(_pixel, PairingFailure.timedOut),
          onPair: () => retried = true,
        ),
      ),
    );

    expect(find.text("Pixel 7 didn't answer."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('the empty list says it found nothing and offers to look again', (
    tester,
  ) async {
    var looked = false;

    await tester.pumpWidget(
      testApp(
        NearbyNotice(
          body:
              'No devices found. Open Ferret on your other device, '
              'on the same Wi-Fi.',
          actionLabel: 'Look again',
          onAction: () => looked = true,
        ),
      ),
    );

    await tester.tap(find.text('Look again'));
    expect(looked, isTrue);
  });
}
