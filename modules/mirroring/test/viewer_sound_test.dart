import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

import 'helpers/fakes.dart';

/// The viewer and the sound of the screen it shows, over a way that never
/// asks (the cable).
void main() {
  late FakeHost host;
  late FakeRoute cable;
  late FakeReceiver receiver;
  late MirrorRoutes routes;
  late MirrorViewer viewer;
  late MirroringSettings settings;
  late MirrorTarget galaxy;
  late List<FakeAudioSink> sinks;
  late DateTime now;
  var refuseSound = false;

  const opus = MirrorAudioConfig(codec: .opus);

  /// 20 ms of Opus, going by its first byte.
  FeedAudio sound(int index) => FeedAudio(
    MirrorAudioPacket(
      data: Uint8List.fromList([0xFC, index]),
      ptsUs: index * 20000,
    ),
  );

  Future<void> create({
    List<MirrorAudioCodec> audioCodecs = const [.opus, .pcm],
    Map<String, Object?> stored = const {},
  }) async {
    host = await FakeHost.create(
      settings: {MirroringSettings.lookForCableKey: true, ...stored},
    );
    cable = FakeRoute('cable');
    receiver = FakeReceiver('cast');
    galaxy = cable.target('a1', 'Galaxy');
    sinks = [];
    now = DateTime(2026, 11, 19, 10);
    settings = MirroringSettings(host.settings);
    routes = MirrorRoutes(
      ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
      settings: settings,
      receiverName: () => 'MacBook',
      routes: [cable],
      receivers: [receiver],
    )..start();
    viewer = MirrorViewer(
      routes: routes,
      createDecoder: FakeDecoder.new,
      codecs: const [.h264],
      settings: settings,
      createAudioSink: () {
        final sink = FakeAudioSink()..refuse = refuseSound;
        sinks.add(sink);
        return sink;
      },
      audioCodecs: audioCodecs,
      clock: () => now,
    );
    await settle();
  }

  Future<FakeFeed> show() async {
    await viewer.startTarget(galaxy);
    final feed = cable.feeds.last..play();
    await settle();
    return feed;
  }

  setUp(() {
    refuseSound = false;
    return create();
  });

  tearDown(() async {
    await viewer.dispose();
    await routes.dispose();
  });

  test('asks for sound by default, in what this computer plays', () async {
    await show();

    expect(cable.options.single.audioCodecs, [
      MirrorAudioCodec.opus,
      MirrorAudioCodec.pcm,
    ]);
    expect(viewer.soundOn, isTrue);
    expect(viewer.current?.sound, ViewSound.starting);
    expect(sinks, isEmpty, reason: 'no output opened before sound arrives');
  });

  test('plays the sound once enough of it waits', () async {
    final feed = await show();

    feed.emit(const FeedAudioConfigured(opus));
    await settle();
    for (var index = 0; index < 5; index++) {
      feed.emit(sound(index));
    }

    expect(viewer.current?.sound, ViewSound.playing);
    expect(sinks.single.configs, [opus]);
    expect(sinks.single.played.map((packet) => packet.ptsUs), [
      0,
      20000,
      40000,
      60000,
      80000,
    ]);
  });

  test('says why when the device cannot send its sound', () async {
    final feed = await show();

    feed.emit(const FeedAudioUnavailable(.unsupported));
    await settle();

    expect(viewer.current?.sound, ViewSound.unsupported);
    expect(viewer.current?.phase, ViewPhase.streaming);
    expect(sinks, isEmpty);
  });

  test('says so when this computer cannot play it, and keeps the '
      'picture', () async {
    refuseSound = true;
    final feed = await show();

    feed.emit(const FeedAudioConfigured(opus));
    await settle();
    feed.emit(sound(0));

    expect(viewer.current?.sound, ViewSound.noOutput);
    expect(viewer.current?.phase, ViewPhase.streaming);
    expect(sinks.single.played, isEmpty);
  });

  test('turning sound off opens the picture again without it, so the phone '
      'plays its own sound', () async {
    final feed = await show();
    feed.emit(const FeedAudioConfigured(opus));
    await settle();

    await viewer.setSound(false);
    await settle();

    expect(settings.sound, isFalse);
    expect(feed.stops, 1);
    expect(cable.options.last.audioCodecs, isEmpty);
    expect(sinks.single.disposed, isTrue);
    expect(viewer.current?.sound, ViewSound.off);
    expect(viewer.current?.isLive, isTrue);
  });

  test('turning it back on asks for sound again', () async {
    await viewer.setSound(false);
    await show();
    expect(cable.options.single.audioCodecs, isEmpty);
    expect(viewer.current?.sound, ViewSound.off);

    await viewer.setSound(true);
    await settle();

    expect(cable.options.last.audioCodecs, isNotEmpty);
    expect(viewer.current?.sound, ViewSound.starting);
  });

  test('the volume is kept and reaches the output', () async {
    final feed = await show();
    feed.emit(const FeedAudioConfigured(opus));
    await settle();

    await viewer.setSoundVolume(0.4);

    expect(sinks.single.volume, 0.4);
    expect(settings.soundVolume, 0.4);
    expect(viewer.soundVolume, 0.4);
  });

  test('a stored volume is set before the first sound', () async {
    await viewer.dispose();
    await routes.dispose();
    await create(stored: {MirroringSettings.soundVolumeKey: 0.25});
    final feed = await show();

    feed.emit(const FeedAudioConfigured(opus));
    await settle();

    expect(sinks.single.volume, 0.25);
  });

  test('stopping closes the output', () async {
    final feed = await show();
    feed.emit(const FeedAudioConfigured(opus));
    await settle();

    await viewer.stop();
    feed.emit(sound(0));

    expect(sinks.single.disposed, isTrue);
    expect(sinks.single.played, isEmpty);
  });

  test('a computer that cannot play sound never asks for it', () async {
    await viewer.dispose();
    await routes.dispose();
    await create(audioCodecs: const []);
    final feed = await show();

    feed.emit(const FeedAudioConfigured(opus));
    await settle();

    expect(cable.options.single.audioCodecs, isEmpty);
    expect(viewer.soundOn, isFalse);
    expect(viewer.current?.sound, ViewSound.off);
    expect(sinks, isEmpty);
  });

  test('a device that shows itself brings no sound to ask for', () async {
    final iphone = FakeFeed(
      const MirrorTarget(routeId: 'airplay', id: 'i1', name: 'iPhone'),
    );
    receiver.receive(iphone);
    await viewer.showIncoming(iphone);
    iphone.play();
    await settle();

    await viewer.setSound(false);

    expect(viewer.current?.sound, ViewSound.off);
    expect(iphone.stops, 0, reason: 'nothing to open again');
  });
}
