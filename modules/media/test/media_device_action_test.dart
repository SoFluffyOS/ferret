import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';

import 'support/fake_host.dart';
import 'support/test_app.dart';

class _Model extends MediaViewModel {
  _Model(super.feature, this._players);

  final List<RemotePlayer> _players;
  PlayerKey? picked;

  @override
  List<RemotePlayer> get players => _players;

  @override
  void select(PlayerKey key) => picked = key;
}

class _Ui extends MediaFeatureUi {
  _Ui(MediaFeature feature, this._model) : super(feature: feature);

  final _Model _model;

  @override
  MediaViewModel get viewModel => _model;
}

class _NoContext extends Fake implements FeatureContext {}

RemotePlayer _player(String id, {required bool playing}) => RemotePlayer(
  deviceId: 'pixel',
  deviceName: 'Pixel 9',
  player: MediaPlayer(
    playerId: id,
    appName: id,
    status: switch (playing) {
      true => .MEDIA_PLAYBACK_STATUS_PLAYING,
      false => .MEDIA_PLAYBACK_STATUS_PAUSED,
    },
  ),
  positionAtMs: 0,
  lastActiveAtMs: 0,
);

void main() {
  final pixel = TrustedDevice(
    id: 'pixel',
    name: 'Pixel 9',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );
  final laptop = TrustedDevice(
    id: 'laptop',
    name: 'MacBook',
    platform: .PLATFORM_MACOS,
    formFactor: .FORM_FACTOR_LAPTOP,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );

  Future<List<FeatureAction>> actionsFor(
    WidgetTester tester,
    List<RemotePlayer> players,
    TrustedDevice device,
  ) async {
    final feature = MediaFeature();
    await feature.start(FakeHost());
    final ui = _Ui(feature, _Model(feature, players));
    late List<FeatureAction> actions;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            actions = ui.deviceActions(
              context,
              _NoContext(),
              DeviceStatus(device, null),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return actions;
  }

  testWidgets('a device that plays something gets Now playing', (
    tester,
  ) async {
    final actions = await actionsFor(tester, [
      _player('podcasts', playing: false),
      _player('spotify', playing: true),
    ], pixel);

    expect(actions.single.label, 'Now playing');
    expect(actions.single.tooltip, 'Control what plays on Pixel 9');
  });

  testWidgets('a device with nothing playing gets no button', (tester) async {
    final actions = await actionsFor(tester, [
      _player('spotify', playing: true),
    ], laptop);

    expect(actions, isEmpty);
  });
}
