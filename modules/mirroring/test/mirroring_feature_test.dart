import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';

import 'helpers/fakes.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = MirroringFeatureUi();

    expect(ui.featureId, MirroringFeature.featureId);
    expect(ui.feature.id, MirroringFeature.featureId);
  });

  test('a phone offers its screen, a computer offers to show it', () {
    final phone = MirroringFeature(canShare: true, canView: false);
    final computer = MirroringFeature(canShare: false, canView: true);

    expect(phone.flags, [MirroringFeature.shareFlag]);
    expect(computer.flags, [MirroringFeature.viewFlag]);
  });

  test('a computer only shows devices that can share', () async {
    final computer = MirroringFeature(
      decoder: FakeDecoder.new,
      codecs: const [.jpeg],
      canShare: false,
      canView: true,
    );
    await computer.start(await FakeHost.create());

    expect(computer.canViewDevice(FakeSession('pixel')), isTrue);
    expect(computer.canViewDevice(FakeSession('mac', flags: [])), isFalse);
    expect(
      computer.canViewDevice(FakeSession('old', supported: false)),
      isFalse,
    );
    await computer.stop();
  });

  test('a device that can\'t share turns requests down', () async {
    final computer = MirroringFeature(
      decoder: FakeDecoder.new,
      codecs: const [.jpeg],
      canShare: false,
      canView: true,
    );
    await computer.start(await FakeHost.create());

    final reply = await computer.onEnvelope(
      FakeSession('other'),
      envelopeOf(StartRequest(version: 1), expectsReply: true),
    );

    expect((reply as StartDeny?)?.reason, DenyReason.DENY_REASON_UNSUPPORTED);
    await computer.stop();
  });

  test('envelopes reach the phone side, and stopping lets go of the '
      'capture', () async {
    final capture = FakeCapture();
    final phone = MirroringFeature(
      capture: () => capture,
      canShare: true,
      canView: false,
      texts: textsFor,
    );
    final host = await FakeHost.create();
    final mac = FakeSession('mac', name: 'MacBook');
    host.sessions = [mac];
    await phone.start(host);

    final reply = await phone.onEnvelope(
      mac,
      envelopeOf(
        StartRequest(version: 1, codecs: const [.CODEC_H264]),
        expectsReply: true,
      ),
    );
    expect(reply, isA<StartPending>());
    capture.answer(.granted);
    await settle();
    expect(phone.source?.active?.deviceName, 'MacBook');

    await phone.onEnvelope(mac, envelopeOf(KeyframeRequest()));
    expect(capture.keyframeRequests, 1);

    await phone.onEnvelope(mac, envelopeOf(Stop()));
    expect(phone.source?.active, isNull);

    await phone.stop();
    expect(capture.disposed, isTrue);
  });

  test('records survive storage, and junk is skipped', () async {
    final host = await FakeHost.create(
      settings: {
        MirroringSettings.historyKey: [
          MirrorRecord(
            deviceId: 'mac',
            deviceName: 'MacBook',
            role: .shared,
            startedAt: DateTime(2026, 11, 18, 21, 10),
            endedAt: DateTime(2026, 11, 18, 21, 22),
            end: .systemEnded,
          ).toJson(),
          'junk',
          {'device_id': 3},
        ],
      },
    );

    final history = MirroringSettings(host.settings).history;

    expect(history, hasLength(1));
    expect(history.single.end, MirrorEnd.systemEnded);
    expect(history.single.duration, const Duration(minutes: 12));
  });

  test('the history keeps the last 20', () async {
    final host = await FakeHost.create();
    final settings = MirroringSettings(host.settings);

    for (var minute = 0; minute < 25; minute++) {
      await settings.addRecord(
        MirrorRecord(
          deviceId: 'mac',
          deviceName: 'MacBook',
          role: .shared,
          startedAt: DateTime(2026, 11, 18, 21, minute),
          endedAt: DateTime(2026, 11, 18, 21, minute + 1),
          end: .viewerDone,
        ),
      );
    }

    expect(settings.history, hasLength(20));
    expect(settings.history.first.startedAt.minute, 24);
  });
}
