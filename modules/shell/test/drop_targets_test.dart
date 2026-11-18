import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
// The host API is only reachable from the plugin's sources.
// ignore: implementation_imports
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

TrustedDevice _device(String id, String name) => TrustedDevice(
  id: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
);

class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHost extends ChangeNotifier implements EngineHost {
  _FakeHost(this.devices);

  @override
  final List<DeviceStatus> devices;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifier implements LocalNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMenubarApi implements MenubarHostApi {
  final List<bool> allowed = [];
  int shown = 0;
  int closed = 0;

  @override
  Future<void> setDropAllowed(bool allowed) async => this.allowed.add(allowed);

  @override
  Future<void> showPopover() async => shown++;

  @override
  Future<void> closeIfOpenedByDrag() async => closed++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Takes every drop, remembers where it went, and reports what the test
/// feeds into [progress].
class _RecordingFeature extends FeatureUi {
  final List<(List<String>, String?)> drops = [];
  StreamController<FilesSendProgress> progress = StreamController();

  @override
  Future<Stream<FilesSendProgress>?> onFilesDropped(
    FeatureContext feature,
    List<String> paths, {
    String? deviceId,
  }) async {
    drops.add((paths, deviceId));
    return progress.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMenubarApi api;
  late FerretMenubar menubar;
  late _RecordingFeature feature;

  setUp(() {
    api = _FakeMenubarApi();
    menubar = FerretMenubar(api: api);
    feature = _RecordingFeature();
  });

  Future<void> pumpZone(
    WidgetTester tester, {
    required List<DeviceStatus> devices,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<EngineHost>.value(
        value: _FakeHost(devices),
        child: ShellScope(
          features: [feature],
          featureContext: FeatureContext(
            engine: _FakeEngine(),
            navigatorKey: GlobalKey<NavigatorState>(),
            notifier: _FakeNotifier(),
          ),
          child: testApp(
            FileDropZone(menubar: menubar, child: const Text('Home')),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  final pixel = DeviceStatus(_device('pixel-id', 'Pixel 7'), _FakeSession());
  final ipad = DeviceStatus(_device('ipad-id', 'iPad'), _FakeSession());
  final tablet = DeviceStatus(_device('tablet-id', 'Old tablet'), null);

  testWidgets('a drag shows one tile per device, offline ones faded', (
    tester,
  ) async {
    await pumpZone(tester, devices: [pixel, ipad, tablet]);
    expect(find.byType(DropTargetTile), findsNothing);

    menubar.onDragEntered(10, 10, 3);
    await settle(tester);

    expect(find.text('Send 3 files to…'), findsOneWidget);
    expect(find.text('Pixel 7'), findsOneWidget);
    expect(find.text('iPad'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('All my devices'), findsOneWidget);
  });

  testWidgets('the tile under the pointer lights up and takes the drop', (
    tester,
  ) async {
    await pumpZone(tester, devices: [pixel, ipad]);
    menubar.onDragEntered(10, 10, 1);
    await settle(tester);

    final overIpad = tester.getCenter(find.text('iPad'));
    menubar.onDragUpdated(overIpad.dx, overIpad.dy);
    await settle(tester);
    expect(find.text('Drop to send'), findsOneWidget);
    expect(api.allowed.last, isTrue);

    menubar.onDragPerformed(['/a.jpg'], overIpad.dx, overIpad.dy);
    await settle(tester);
    expect(feature.drops.single.$1, ['/a.jpg']);
    expect(feature.drops.single.$2, 'ipad-id');
    expect(find.text('Sending to iPad'), findsOneWidget);

    feature.progress.add(const FilesSent());
    await settle(tester);
    expect(find.text('Sent to iPad'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);
    expect(find.byType(DropProgressCard), findsNothing);
    expect(api.closed, 1);
  });

  testWidgets('an offline tile refuses the drop', (tester) async {
    await pumpZone(tester, devices: [pixel, tablet]);
    menubar.onDragEntered(10, 10, 1);
    await settle(tester);

    final overTablet = tester.getCenter(find.text('Old tablet'));
    menubar.onDragUpdated(overTablet.dx, overTablet.dy);
    await settle(tester);
    expect(api.allowed.last, isFalse);

    menubar.onDragPerformed(['/a.jpg'], overTablet.dx, overTablet.dy);
    await settle(tester);
    expect(feature.drops, isEmpty);
    expect(find.byType(DropTargetTile), findsNothing);
  });

  testWidgets('a failure says why and can be tried again', (tester) async {
    await pumpZone(tester, devices: [pixel]);
    menubar.onDragEntered(10, 10, 1);
    await settle(tester);
    final overPixel = tester.getCenter(find.text('Pixel 7'));
    menubar.onDragPerformed(['/a.jpg'], overPixel.dx, overPixel.dy);
    await settle(tester);

    feature.progress.add(const FilesSendFailed('Pixel 7 went offline.'));
    await settle(tester);
    expect(find.text("Couldn't send to Pixel 7"), findsOneWidget);
    expect(find.text('Pixel 7 went offline.'), findsOneWidget);
    expect(api.shown, 1);

    feature.progress = StreamController();
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(feature.drops, hasLength(2));
  });

  testWidgets('a blind drop on the icon with two devices asks which', (
    tester,
  ) async {
    await pumpZone(tester, devices: [pixel, ipad]);

    menubar.onFilesDropped(['/a.jpg', '/b.jpg']);
    await settle(tester);
    expect(api.shown, 1);
    expect(find.text('Send 2 files to…'), findsOneWidget);
    expect(find.text('Send here'), findsNWidgets(3));

    await tester.tap(find.text('Pixel 7'));
    await settle(tester);
    expect(feature.drops.single.$2, 'pixel-id');
  });

  testWidgets('with nobody connected it says what to do first', (
    tester,
  ) async {
    await pumpZone(tester, devices: [tablet]);
    menubar.onDragEntered(10, 10, 1);
    await settle(tester);

    expect(find.text('No devices connected'), findsOneWidget);
    expect(find.text('Open Ferret on your phone first.'), findsOneWidget);
    expect(find.text('All my devices'), findsNothing);
  });
}
