@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/photos.dart';
import 'package:protocol/photos.dart';
import 'package:protocol/protocol.dart';

import 'helpers/fake_photo_library.dart';
import 'helpers/fake_transfers.dart';
import 'helpers/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDiscoveryBus bus;
  late Directory cacheRoot;
  final engines = <FerretEngine>[];
  final now = DateTime(2026, 11, 19, 10);

  setUp(() async {
    bus = MemoryDiscoveryBus();
    cacheRoot = await Directory.systemTemp.createTemp('photos_cache');
  });

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
    await cacheRoot.delete(recursive: true);
  });

  Future<FerretEngine> startEngine(
    String name,
    PhotosFeature feature, {
    FormFactor formFactor = .FORM_FACTOR_LAPTOP,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: formFactor,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting');
  }

  /// A laptop and a phone, paired. Returns the phone's id on the laptop
  /// and the laptop's id on the phone.
  Future<(String, String)> pair(FerretEngine laptop, FerretEngine phone) async {
    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);

    return (
      laptop.sessions.single.remoteDeviceId,
      phone.sessions.single.remoteDeviceId,
    );
  }

  List<PhotoEntry> library(int count) => [
    for (var index = 0; index < count; index++)
      entry('p$index', now.subtract(Duration(minutes: index))),
  ];

  Future<
    ({
      PhotosFeature computer,
      PhotosFeature phoneFeature,
      FakePhotoLibrary photos,
      FakeTransfers computerTransfers,
      FakeTransfers phoneTransfers,
      String phoneId,
      String laptopId,
    })
  >
  setUpPair({
    List<PhotoEntry>? entries,
    PhotoLibraryAccess access = .full,
  }) async {
    final photos = FakePhotoLibrary(
      entries: entries ?? library(5),
      accessNow: access,
    );
    final computerTransfers = FakeTransfers();
    final phoneTransfers = FakeTransfers();
    final computer = PhotosFeature(
      library: const UnsupportedPhotoLibrary(),
      cache: ThumbnailCache(cacheRoot.path),
      transfers: computerTransfers,
      now: () => now,
    );
    final phoneFeature = PhotosFeature(
      library: photos,
      transfers: phoneTransfers,
      now: () => now,
    );
    final laptop = await startEngine('Laptop', computer);
    final phone = await startEngine(
      'Pixel',
      phoneFeature,
      formFactor: .FORM_FACTOR_PHONE,
    );
    final (phoneId, laptopId) = await pair(laptop, phone);

    return (
      computer: computer,
      phoneFeature: phoneFeature,
      photos: photos,
      computerTransfers: computerTransfers,
      phoneTransfers: phoneTransfers,
      phoneId: phoneId,
      laptopId: laptopId,
    );
  }

  test('a phone shares nothing until its owner allows that computer', () async {
    final setup = await setUpPair();

    final denied = await setup.computer.list(setup.phoneId);
    expect(denied.access, PhotoAccess.PHOTO_ACCESS_NOT_ALLOWED);
    expect(denied.items, isEmpty);
    expect(
      await setup.computer.thumbnail(setup.phoneId, 'p0', maxPx: 320),
      isNull,
    );

    await setup.phoneFeature.setSharesWith(setup.laptopId, shared: true);
    final allowed = await setup.computer.list(setup.phoneId);
    expect(allowed.access, PhotoAccess.PHOTO_ACCESS_FULL);
    expect(allowed.items.first.id, 'p0');
  });

  test(
    'turning sharing on asks the phone for photo access in context',
    () async {
      final setup = await setUpPair(access: .notAsked);

      final access = await setup.phoneFeature.setSharesWith(
        setup.laptopId,
        shared: true,
      );

      expect(setup.photos.requests, 1);
      expect(access, PhotoLibraryAccess.full);
    },
  );

  test('permission states reach the computer', () async {
    final setup = await setUpPair(access: .denied);
    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: true,
    );

    expect(
      (await setup.computer.list(setup.phoneId)).access,
      PhotoAccess.PHOTO_ACCESS_NO_PERMISSION,
    );

    setup.photos.accessNow = .limited;
    expect(
      (await setup.computer.list(setup.phoneId)).access,
      PhotoAccess.PHOTO_ACCESS_LIMITED,
    );

    setup.photos.accessNow = .unavailable;
    expect(
      (await setup.computer.list(setup.phoneId)).access,
      PhotoAccess.PHOTO_ACCESS_UNAVAILABLE,
    );
  });

  test('the gallery pages newest first and never repeats a photo', () async {
    final setup = await setUpPair(entries: library(7));
    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: true,
    );
    final gallery = PhotoGalleryViewModel(
      setup.computer,
      setup.phoneId,
      pageSize: 3,
    );
    addTearDown(gallery.dispose);

    await gallery.load();
    expect(gallery.state, GalleryState.photos);
    expect([for (final item in gallery.items) item.id], ['p0', 'p1', 'p2']);
    expect(gallery.hasMore, isTrue);

    // A photo taken while paging shifts the phone's pages by one.
    setup.photos.entries.insert(0, entry('new', now));
    await gallery.loadMore();
    await gallery.loadMore();
    await gallery.loadMore();

    expect(
      [for (final item in gallery.items) item.id],
      ['p0', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
    );
    expect(gallery.hasMore, isFalse);

    await gallery.load();
    expect(gallery.items.first.id, 'new');
  });

  test('a thumbnail is asked for once, then comes from the cache', () async {
    final setup = await setUpPair();
    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: true,
    );

    final first = await setup.computer.thumbnail(
      setup.phoneId,
      'p1',
      maxPx: 320,
    );
    final second = await setup.computer.thumbnail(
      setup.phoneId,
      'p1',
      maxPx: 320,
    );

    expect(first, isNotNull);
    expect(second, first);
    expect(setup.photos.thumbnailCalls, 1);
  });

  test('saving fetches the full files through the transfer', () async {
    final setup = await setUpPair();
    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: true,
    );

    final saving = setup.computer.save(setup.phoneId, ['p0', 'p2', 'gone']);
    await until(() => setup.computerTransfers.isFollowing('transfer-1'));

    expect(setup.phoneTransfers.sent.single.$1, setup.laptopId);
    expect(setup.phoneTransfers.sent.single.$2, [
      '/tmp/export/p0.jpg',
      '/tmp/export/p2.jpg',
    ]);
    expect(setup.computer.saves.all.single.status, PhotoTransferStatus.running);
    expect(setup.computer.saves.all.single.count, 2);

    setup.computerTransfers.finish('transfer-1', ['/r/p0.jpg', '/r/p2.jpg']);
    final save = await saving;

    expect(save.status, PhotoTransferStatus.done);
    expect(save.paths, ['/r/p0.jpg', '/r/p2.jpg']);

    expect(await setup.computer.openSaved('/r/p0.jpg'), isTrue);
    expect(await setup.computer.revealSaved('/r/p2.jpg'), isTrue);
    expect(setup.computerTransfers.opened, ['/r/p0.jpg']);
    expect(setup.computerTransfers.revealed, ['/r/p2.jpg']);
  });

  test('saving from a phone that does not share fails with why', () async {
    final setup = await setUpPair();

    final save = await setup.computer.save(setup.phoneId, ['p0']);

    expect(save.status, PhotoTransferStatus.failed);
    expect(save.problem, PhotoSaveProblem.notAllowed);
    expect(setup.phoneTransfers.sent, isEmpty);
  });

  test('new screenshots arrive by themselves once turned on', () async {
    final setup = await setUpPair();
    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: true,
    );
    await setup.computer.setAutoScreenshots(setup.phoneId, enabled: true);
    await until(() => setup.photos.screenshots.hasListener);

    final shot = entry('s1', now, kind: .screenshot);
    setup.photos.entries.insert(0, shot);
    setup.photos.screenshots
      ..add(
        entry('old', now.subtract(const Duration(hours: 1)), kind: .screenshot),
      )
      ..add(entry('p9', now, kind: .photo))
      ..add(shot)
      ..add(shot);
    await until(() => setup.computer.saves.all.isNotEmpty);

    expect(setup.phoneTransfers.sent, hasLength(1));
    expect(setup.photos.exported, ['s1']);
    expect(setup.computer.saves.all.single.isScreenshot, isTrue);

    setup.computerTransfers.finish('transfer-1', ['/r/s1.png']);
    await until(
      () => setup.computer.saves.all.single.status == PhotoTransferStatus.done,
    );
  });

  test('screenshots stop when the owner stops sharing', () async {
    final setup = await setUpPair();
    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: true,
    );
    await setup.computer.setAutoScreenshots(setup.phoneId, enabled: true);
    await until(() => setup.photos.screenshots.hasListener);

    await setup.phoneFeature.settings.setSharesWith(
      setup.laptopId,
      shared: false,
    );

    await until(() => !setup.photos.screenshots.hasListener);
  });

  test('a computer that asks puts a prompt on the phone', () async {
    final setup = await setUpPair();
    final prompts = setup.phoneFeature.accessPrompts.first;

    expect(await setup.computer.askForAccess(setup.phoneId), isTrue);
    expect(await prompts, setup.laptopId);
  });
}
