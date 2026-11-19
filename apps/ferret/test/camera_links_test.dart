// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret/wiring/wiring.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_camera/phone_camera.dart';
import 'package:photos/photos.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

class _NoDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}

class _Clipboard implements ClipboardPlatform {
  final List<ClipboardContent> writes = [];

  @override
  ClipboardAccess get access => .always;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<ClipboardContent?> read() async => writes.lastOrNull;

  @override
  Future<void> write(ClipboardContent content) async => writes.add(content);

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}
}

void main() {
  test('a transfer\'s progress reads the same for the camera', () {
    final running = DropCaptureTransfers.progressOf(
      const PhotoTransferProgress(status: .running, fraction: 0.5),
    );
    final done = DropCaptureTransfers.progressOf(
      const PhotoTransferProgress(status: .done, paths: ['/r/Photo.jpg']),
    );

    expect(running.status, CaptureTransferStatus.running);
    expect(running.fraction, 0.5);
    expect(done.status, CaptureTransferStatus.done);
    expect(done.paths, ['/r/Photo.jpg']);
    expect(
      DropCaptureTransfers.progressOf(
        const PhotoTransferProgress(status: .failed),
      ).status,
      CaptureTransferStatus.failed,
    );
  });

  test('the picture goes on the clipboard as an image', () async {
    final platform = _Clipboard();
    final clipboard = ClipboardFeature(clipboard: () => platform);
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'MacBook Air',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [clipboard, CameraFeature()],
      discovery: _NoDiscovery(),
      port: 0,
    );
    await engine.start();
    addTearDown(engine.stop);
    CameraLinks.attach(engine);
    final paste = engine.feature<CameraFeature>()?.paste;
    if (paste == null) {
      fail('The camera should be joined to the clipboard');
    }
    final photo = Uint8List.fromList([0xff, 0xd8, 0xff, 1]);

    expect(await paste.putImage(photo, mimeType: 'image/jpeg'), isTrue);

    expect(platform.writes.single.image, photo);
    expect(platform.writes.single.imageMime, 'image/jpeg');
  });
}
