import 'package:pigeon/pigeon.dart';

// Linux reads MPRIS over D-Bus in Dart (lib/src/linux), so it has no native
// output here.
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_media',
    dartOut: 'lib/src/messages.g.dart',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'ferret_media'),
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_media/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_media'),
    swiftOut: [
      'ios/ferret_media/Sources/ferret_media/Messages.g.swift',
      'macos/ferret_media/Sources/ferret_media/Messages.g.swift',
    ],
  ),
)
/// Whether this app may see and control other apps' media.
enum MediaAccess {
  /// Ferret can see and control media players.
  granted,

  /// The user has to allow it first, such as Notification access on Android
  /// or Automation on macOS.
  notGranted,

  /// The platform never lets apps see other apps' media, such as iOS.
  unsupported,
}

enum PlayerStatus { stopped, paused, playing, buffering }

enum PlayerAction { play, pause, toggle, next, previous, seek, setVolume }

/// One media player on this device and what it plays.
class PlayerInfo {
  PlayerInfo({
    required this.id,
    required this.appId,
    required this.appName,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.positionMs,
    required this.positionAtMs,
    required this.status,
    required this.playbackRate,
    required this.lastActiveAtMs,
    required this.actions,
    required this.volume,
  });

  /// Stable while the player exists.
  String id;
  String appId;
  String appName;
  String title;
  String artist;
  String album;

  /// A small JPEG or PNG, or null.
  Uint8List? artwork;

  /// 0 when unknown.
  int durationMs;
  int positionMs;

  /// Milliseconds since epoch when [positionMs] was true.
  int positionAtMs;
  PlayerStatus status;
  double playbackRate;

  /// A link to the item, such as a spotify: URI, when the player tells it.
  String? contentUri;

  /// Milliseconds since epoch when the player last started or changed item.
  int lastActiveAtMs;
  List<PlayerAction> actions;

  /// 0 to 1, or -1 when unknown.
  double volume;
}

@HostApi()
abstract class MediaHostApi {
  MediaAccess access();

  /// Asks for access where the system can ask in place, such as the macOS
  /// Automation prompt. Returns the access afterwards.
  @async
  MediaAccess requestAccess();

  /// Opens the system page where people allow access, such as Notification
  /// access on Android.
  void openAccessSettings();

  /// Starts reporting players through [MediaFlutterApi.onPlayersChanged].
  void startWatching();

  void stopWatching();

  @async
  List<PlayerInfo> players();

  /// Returns false when the player is gone or refused.
  @async
  bool command(
    String playerId,
    PlayerAction action,
    int positionMs,
    double volume,
  );
}

@FlutterApi()
abstract class MediaFlutterApi {
  void onPlayersChanged(List<PlayerInfo> players);

  void onAccessChanged(MediaAccess access);
}
