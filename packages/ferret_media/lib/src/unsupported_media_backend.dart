import 'package:ferret_media/src/media_backend.dart';
import 'package:ferret_media/src/messages.g.dart';

/// For platforms that can't see other apps' media at all.
class UnsupportedMediaBackend implements MediaBackend {
  const UnsupportedMediaBackend();

  @override
  Stream<List<PlayerInfo>> get players => const Stream.empty();

  @override
  Stream<MediaAccess> get accessChanges => const Stream.empty();

  @override
  Future<MediaAccess> access() async => .unsupported;

  @override
  Future<MediaAccess> requestAccess() async => .unsupported;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}

  @override
  Future<List<PlayerInfo>> currentPlayers() async => const [];

  @override
  Future<bool> command(
    String playerId,
    PlayerAction action, {
    int positionMs = 0,
    double volume = 0,
  }) async => false;
}
