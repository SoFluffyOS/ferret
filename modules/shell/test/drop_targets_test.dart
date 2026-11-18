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
  Future<void> setDropAllowed(int viewId, bool allowed) async =>
      this.allowed.add(allowed);

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

/// The view the test's widgets draw in, which the drags are over.
int get _viewId =>
    WidgetsBinding.instance.platformDispatcher.implicitView?.viewId ?? 0;

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
    Size size = const Size(380, 560),
    Widget child = const Text('Home'),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
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
            FileDropZone(menubar: menubar, child: child),
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

    menubar.onDragEntered(_viewId, 10, 10, 3);
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
    menubar.onDragEntered(_viewId, 10, 10, 1);
    await settle(tester);

    final overIpad = tester.getCenter(find.text('iPad'));
    menubar.onDragUpdated(_viewId, overIpad.dx, overIpad.dy);
    await settle(tester);
    expect(find.text('Drop to send'), findsOneWidget);
    expect(api.allowed.last, isTrue);

    menubar.onDragPerformed(_viewId, ['/a.jpg'], overIpad.dx, overIpad.dy);
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
    menubar.onDragEntered(_viewId, 10, 10, 1);
    await settle(tester);

    final overTablet = tester.getCenter(find.text('Old tablet'));
    menubar.onDragUpdated(_viewId, overTablet.dx, overTablet.dy);
    await settle(tester);
    expect(api.allowed.last, isFalse);

    menubar.onDragPerformed(_viewId, ['/a.jpg'], overTablet.dx, overTablet.dy);
    await settle(tester);
    expect(feature.drops, isEmpty);
    expect(find.byType(DropTargetTile), findsNothing);
  });

  testWidgets('a failure says why and can be tried again', (tester) async {
    await pumpZone(tester, devices: [pixel]);
    menubar.onDragEntered(_viewId, 10, 10, 1);
    await settle(tester);
    final overPixel = tester.getCenter(find.text('Pixel 7'));
    menubar.onDragPerformed(_viewId, ['/a.jpg'], overPixel.dx, overPixel.dy);
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
    menubar.onDragEntered(_viewId, 10, 10, 1);
    await settle(tester);

    expect(find.text('No device to send to'), findsOneWidget);
    expect(
      find.text('Open Ferret on your other device first.'),
      findsOneWidget,
    );
    expect(find.text('All my devices'), findsNothing);
  });

  group('in a window', () {
    const windowSize = Size(1000, 720);
    final page = Row(
      children: [
        SizedBox(
          width: 240,
          child: Column(
            children: [
              DropTargetRegion(
                target: WindowDropTargets.device(pixel),
                child: const Text('Pixel row'),
              ),
              DropTargetRegion(
                target: WindowDropTargets.device(tablet),
                child: const Text('Tablet row'),
              ),
            ],
          ),
        ),
        Expanded(
          child: DropTargetRegion(
            target: PaneDropTarget(WindowDropTargets.device(pixel)),
            child: const Center(child: Text('Page')),
          ),
        ),
      ],
    );

    testWidgets('a drag keeps the page and finds the row under the pointer', (
      tester,
    ) async {
      await pumpZone(
        tester,
        devices: [pixel, tablet],
        size: windowSize,
        child: page,
      );
      menubar.onDragEntered(_viewId, 600, 300, 1);
      await settle(tester);

      expect(find.byType(DropTargetTile), findsNothing);
      expect(find.text('Page'), findsOneWidget);

      final overTablet = tester.getCenter(find.text('Tablet row'));
      menubar.onDragUpdated(_viewId, overTablet.dx, overTablet.dy);
      await settle(tester);
      expect(api.allowed.last, isFalse);

      final overPixel = tester.getCenter(find.text('Pixel row'));
      menubar.onDragUpdated(_viewId, overPixel.dx, overPixel.dy);
      await settle(tester);
      expect(api.allowed.last, isTrue);

      menubar.onDragPerformed(_viewId, ['/a.jpg'], overPixel.dx, overPixel.dy);
      await settle(tester);
      expect(feature.drops.single.$2, 'pixel-id');
      expect(find.text('Sending to Pixel 7'), findsOneWidget);
      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('the pane sends to the device it shows', (tester) async {
      await pumpZone(
        tester,
        devices: [pixel, tablet],
        size: windowSize,
        child: page,
      );
      final overPage = tester.getCenter(find.text('Page'));
      menubar.onDragEntered(_viewId, overPage.dx, overPage.dy, 1);
      await settle(tester);
      expect(api.allowed.last, isTrue);

      menubar.onDragPerformed(_viewId, ['/a.jpg'], overPage.dx, overPage.dy);
      await settle(tester);

      expect(feature.drops.single.$2, 'pixel-id');
      expect(find.text('Sending to Pixel 7'), findsOneWidget);
    });

    testWidgets('a blind drop still asks which device', (tester) async {
      await pumpZone(
        tester,
        devices: [pixel, ipad],
        size: windowSize,
        child: page,
      );

      menubar.onFilesDropped(['/a.jpg']);
      await settle(tester);

      expect(find.text('Send here'), findsNWidgets(3));
    });
  });

  test('files dropped on no device go to the connected ones', () {
    expect(WindowDropTargets.everyone([tablet]), isNull);
    expect(
      WindowDropTargets.everyone([pixel, tablet]),
      WindowDropTargets.device(pixel),
    );
    expect(
      WindowDropTargets.everyone([pixel, ipad]),
      const AllDevicesDropTarget(),
    );
  });

  testWidgets('resting on a row opens it after a moment, once', (
    tester,
  ) async {
    var opened = 0;
    Widget spring({required bool active}) => DropSpringOpen(
      active: active,
      onOpen: () => opened++,
      child: const SizedBox.shrink(),
    );

    await tester.pumpWidget(spring(active: true));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(spring(active: false));
    await tester.pump(const Duration(seconds: 1));
    expect(opened, 0);

    await tester.pumpWidget(spring(active: true));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(spring(active: true));
    await tester.pump(const Duration(seconds: 1));
    expect(opened, 1);
  });
}
