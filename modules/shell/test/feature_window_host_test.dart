import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
// The pigeon API is what a fake of the Mac side implements.
// ignore: implementation_imports
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

class _FakeMenubarApi implements MenubarHostApi {
  _FakeMenubarApi(this.viewId);

  final int viewId;
  final List<String> opened = [];
  final List<Size> sizes = [];
  int focused = 0;
  int dragged = 0;
  int closed = 0;

  @override
  Future<bool> isWindowSupported() async => true;

  @override
  Future<int> openPictureWindow(
    String id,
    String title,
    double width,
    double height,
    double barHeight,
  ) async {
    opened.add(
      '$id: $title, ${width.round()} × ${height.round()}, bar ${barHeight.round()}',
    );
    return viewId;
  }

  @override
  Future<void> setPictureWindowSize(double width, double height) async =>
      sizes.add(Size(width, height));

  @override
  Future<void> focusPictureWindow() async => focused++;

  @override
  Future<void> dragPictureWindow() async => dragged++;

  @override
  Future<void> closePictureWindow() async => closed++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FeatureWindow _screenOf(String id, String name) => FeatureWindow(
  id: id,
  title: '$name — Screen',
  contentSize: const Size(1080, 2400),
  barHeight: 32,
  builder: (_) => Text(name),
);

void main() {
  late _FakeMenubarApi api;
  late FerretMenubar menubar;
  late FeatureWindowHost host;

  Future<void> start(WidgetTester tester) async {
    api = _FakeMenubarApi(tester.view.viewId);
    menubar = FerretMenubar(api: api);
    host = FeatureWindowHost(menubar: menubar);
    addTearDown(host.dispose);
    await host.start();
  }

  testWidgets('a window left over from before the app restarted is closed', (
    tester,
  ) async {
    await start(tester);

    expect(host.canOpen, isTrue);
    expect(host.openId, isNull);
    expect(api.closed, 1);
  }, skip: !Platform.isMacOS);

  testWidgets('a feature\'s window opens in its shape with its bar, with a '
      'view to draw in, and asking again only brings it forward', (
    tester,
  ) async {
    await start(tester);
    var changes = 0;
    host.addListener(() => changes++);

    expect(await host.open(_screenOf('pixel', 'Pixel 9')), isTrue);

    expect(api.opened, ['pixel: Pixel 9 — Screen, 1080 × 2400, bar 32']);
    expect(host.openId, 'pixel');
    expect(host.view?.viewId, tester.view.viewId);
    expect(changes, greaterThan(0));

    expect(await host.open(_screenOf('pixel', 'Pixel 9')), isTrue);
    expect(api.opened, hasLength(1));
    expect(api.focused, 1);

    await host.setContentSize(const Size(2400, 1080));
    expect(api.sizes, [const Size(2400, 1080)]);

    await host.startDrag();
    expect(api.dragged, 1);
  }, skip: !Platform.isMacOS);

  testWidgets('another device takes the window\'s place, and the first '
      'window\'s late goodbye changes nothing', (tester) async {
    await start(tester);
    await host.open(_screenOf('pixel', 'Pixel 9'));

    await host.open(_screenOf('tablet', 'Old tablet'));
    menubar.onPictureWindowClosed(999);
    await tester.pump();

    expect(host.openId, 'tablet');
    expect(host.window?.title, 'Old tablet — Screen');
  }, skip: !Platform.isMacOS);

  testWidgets('closing the window lets go of what it showed', (tester) async {
    await start(tester);
    await host.open(_screenOf('pixel', 'Pixel 9'));

    await host.close();
    menubar.onPictureWindowClosed(tester.view.viewId);
    await tester.pump();

    expect(api.closed, 2);
    expect(host.openId, isNull);
    expect(host.view, isNull);
  }, skip: !Platform.isMacOS);
}
