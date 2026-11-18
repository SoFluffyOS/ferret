import 'package:ferret_media/src/messages.g.dart';

/// One way to see and control the media players on this device.
abstract interface class MediaBackend {
  /// Every player, each time one changes. Only while watching.
  Stream<List<PlayerInfo>> get players;

  /// Fires when the user grants or takes away access.
  Stream<MediaAccess> get accessChanges;

  Future<MediaAccess> access();

  /// Asks for access where the system can ask in place, or opens the page
  /// where people allow it. Returns the access afterwards.
  Future<MediaAccess> requestAccess();

  /// Opens the system page where people allow access.
  Future<void> openAccessSettings();

  Future<void> startWatching();

  Future<void> stopWatching();

  Future<List<PlayerInfo>> currentPlayers();

  /// Returns false when the player is gone or refused.
  Future<bool> command(
    String playerId,
    PlayerAction action, {
    int positionMs = 0,
    double volume = 0,
  });
}
