import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart' show Presence;
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

final _pixel = TrustedDevice(
  id: 'abcdabcdabcdabcd',
  name: 'Pixel',
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
);

class _FakeSession implements Session {
  @override
  bool get isWeak => false;

  @override
  Presence remotePresence = Presence();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _reason = "Pixel didn't get the last link you sent";

Future<void> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  final status = DeviceStatus(_pixel, _FakeSession());

  testWidgets('the orange dot in the device list says which feature and '
      'why', (tester) async {
    await tester.pumpWidget(
      testApp(
        SidebarDeviceRow(
          status: status,
          onTap: () {},
          needsAttention: true,
          attentionReason: 'Connected · Links: $_reason',
        ),
      ),
    );

    expect(
      tester
          .widgetList<FluffyTooltip>(find.byType(FluffyTooltip))
          .map((tooltip) => tooltip.message),
      contains('Connected · Links: $_reason'),
    );
  });

  testWidgets('without a reason, the dot still says it needs attention', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        SidebarDeviceRow(status: status, onTap: () {}, needsAttention: true),
      ),
    );

    expect(
      tester
          .widgetList<FluffyTooltip>(find.byType(FluffyTooltip))
          .map((tooltip) => tooltip.message),
      contains('Connected, needs attention'),
    );
  });

  testWidgets('on Home, the status line explains itself on hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        DeviceTile(
          status: status,
          attention: 'Links',
          attentionReason: _reason,
        ),
      ),
    );

    await _hover(tester, find.text('Connected · Links: needs attention'));

    expect(find.text('Connected · Links: $_reason'), findsOneWidget);
  });

  testWidgets('the Overview names what needs attention, with its fix', (
    tester,
  ) async {
    var fixed = false;
    await tester.pumpWidget(
      testApp(
        NeedsAttentionCard(
          features: [
            (
              title: 'Links',
              health: FeatureHealth(
                .failing,
                reason: _reason,
                onFix: () => fixed = true,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Links'), findsOneWidget);
    expect(find.text(_reason), findsOneWidget);
    await tester.tap(find.text('Fix'));
    expect(fixed, isTrue);
  });

  testWidgets('nothing on the Overview when everything works', (tester) async {
    await tester.pumpWidget(testApp(const NeedsAttentionCard(features: [])));

    expect(find.byType(SurfaceCard), findsNothing);
  });

  test('only what needs the user or failed counts', () {
    expect(DeviceAttention.isBroken(const FeatureHealth(.failing)), isTrue);
    expect(
      DeviceAttention.isBroken(const FeatureHealth(.needsAttention)),
      isTrue,
    );
    expect(DeviceAttention.isBroken(const FeatureHealth(.ok)), isFalse);
    expect(DeviceAttention.isBroken(const FeatureHealth(.off)), isFalse);
  });
}
