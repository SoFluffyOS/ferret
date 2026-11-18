import 'dart:io';

import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/files.dart';
import 'support/linked_devices.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifier implements LocalNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late LinkedDevices link;
  late DropFeatureUi ui;
  late File source;
  final context = FeatureContext(
    engine: _FakeEngine(),
    navigatorKey: GlobalKey<NavigatorState>(),
    notifier: _FakeNotifier(),
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_dropped');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => root.path,
        );
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: folderStore(Directory(p.join(root.path, 'phone'))),
    );
    ui = DropFeatureUi(feature: link.laptop.feature);
    source = await randomFile(root, 'photo.jpg', 2048);
  });

  tearDown(() async {
    await until(
      () => link.laptop.feature.transfers.every(
        (transfer) => !transfer.status.isActive,
      ),
    );
    await ui.dispose();
    await root.delete(recursive: true);
  });

  test('files dropped on a device go to that device', () async {
    final progress = await ui.onFilesDropped(context, [
      source.path,
    ], deviceId: 'phone-id');

    expect(link.laptop.feature.transfers, hasLength(1));
    expect(link.laptop.feature.transfers.single.deviceId, 'phone-id');
    expect(await progress?.last, isA<FilesSent>());
  });

  test('files dropped anywhere else go to every connected device', () async {
    await ui.onFilesDropped(context, [source.path]);

    expect(
      [for (final transfer in link.laptop.feature.transfers) transfer.deviceId],
      ['phone-id'],
    );
  });

  test('files dropped on a device that is gone are not sent', () async {
    final progress = await ui.onFilesDropped(context, [
      source.path,
    ], deviceId: 'tablet-id');

    expect(link.laptop.feature.transfers, isEmpty);
    expect(await progress?.last, isA<FilesSendFailed>());
  });
}
