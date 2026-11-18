import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';

import 'support/fake_host.dart';

/// A view model with a fixed selection that counts the commands it gets.
class _RecordingModel extends MediaViewModel {
  _RecordingModel(super.feature, this._player);

  final RemotePlayer? _player;
  int toggles = 0;
  int nexts = 0;

  @override
  RemotePlayer? get selected => _player;

  @override
  Future<void> togglePlay() async => toggles++;

  @override
  Future<void> next() async => nexts++;
}

RemotePlayer _remote({
  bool playing = true,
  String title = 'Teardrop',
  String artist = 'Massive Attack',
  String appName = 'Spotify',
  List<MediaAction> actions = const [.MEDIA_ACTION_TOGGLE, .MEDIA_ACTION_NEXT],
}) => RemotePlayer(
  deviceId: 'pixel',
  deviceName: 'Pixel',
  player: MediaPlayer(
    playerId: 'spotify',
    appName: appName,
    title: title,
    artist: artist,
    status: switch (playing) {
      true => .MEDIA_PLAYBACK_STATUS_PLAYING,
      false => .MEDIA_PLAYBACK_STATUS_PAUSED,
    },
    actions: actions,
  ),
  positionAtMs: 0,
  lastActiveAtMs: 0,
);

void main() {
  final l10n = lookupMediaLocalizations(const Locale('en'));

  Future<_RecordingModel> modelFor(RemotePlayer? player) async {
    final feature = MediaFeature();
    await feature.start(FakeHost());
    final model = _RecordingModel(feature, player);
    addTearDown(model.dispose);
    return model;
  }

  ActivityItem single(List<ActivityItem> items) {
    expect(items, hasLength(1));
    return items.single;
  }

  group('MediaActivity', () {
    test('has no line while nothing plays', () async {
      final model = await modelFor(null);

      expect(MediaActivity.items(l10n, model), isEmpty);
    });

    test('pins the track and its device, with the artist below', () async {
      final model = await modelFor(_remote());

      final item = single(MediaActivity.items(l10n, model));

      expect(item.id, MediaActivity.itemId);
      expect(item.title, 'Teardrop · Pixel');
      expect(item.detail, 'Massive Attack');
      expect(item.pinned, isTrue);
      expect(item.at, isNull);
      expect(item.actions.map((action) => action.icon), [
        LucideIcons.pause,
        LucideIcons.skipForward,
      ]);
      expect(item.actions.map((action) => action.label), ['Pause', 'Next']);
    });

    test('offers play while paused', () async {
      final model = await modelFor(_remote(playing: false));

      final item = single(MediaActivity.items(l10n, model));

      expect(item.actions.first.icon, LucideIcons.play);
      expect(item.actions.first.label, 'Play');
    });

    test('names the app, then the state, when there is no title', () async {
      final withApp = await modelFor(_remote(title: '', artist: ''));
      final bare = await modelFor(
        _remote(title: '', artist: '', appName: '', playing: false),
      );

      final appItem = single(MediaActivity.items(l10n, withApp));
      final bareItem = single(MediaActivity.items(l10n, bare));

      expect(appItem.title, 'Spotify on Pixel');
      expect(appItem.detail, isNull);
      expect(bareItem.title, 'Paused on Pixel');
    });

    test('leaves out what the player cannot do', () async {
      final model = await modelFor(_remote(actions: const []));

      expect(single(MediaActivity.items(l10n, model)).actions, isEmpty);
    });

    test('the actions and the tap call through', () async {
      final model = await modelFor(_remote());
      var taps = 0;

      final item = single(
        MediaActivity.items(l10n, model, onTap: () => taps++),
      );
      item.actions[0].onPressed();
      item.actions[1].onPressed();
      item.onTap?.call();

      expect(model.toggles, 1);
      expect(model.nexts, 1);
      expect(taps, 1);
    });
  });
}
