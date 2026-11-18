import 'package:dbus/dbus.dart';
import 'package:ferret_media/src/messages.g.dart';

/// Reads the properties of an MPRIS player (`org.mpris.MediaPlayer2.Player`).
class MprisMetadata {
  MprisMetadata(this.properties);

  static const busPrefix = 'org.mpris.MediaPlayer2.';

  final Map<String, DBusValue> properties;

  Map<String, DBusValue> get _metadata => switch (properties['Metadata']) {
    final DBusDict dict => _stringKeyed(dict),
    _ => const {},
  };

  String get title => _string(_metadata['xesam:title']);

  String get artist => switch (_metadata['xesam:artist']) {
    final DBusArray artists =>
      artists.children
          .whereType<DBusString>()
          .map((name) => name.value)
          .join(', '),
    final value => _string(value),
  };

  String get album => _string(_metadata['xesam:album']);

  /// The track's object path, needed to seek.
  String? get trackId => switch (_metadata['mpris:trackid']) {
    final DBusObjectPath path => path.value,
    final DBusString text when text.value.isNotEmpty => text.value,
    _ => null,
  };

  int get durationMs => _micros(_metadata['mpris:length']) ~/ 1000;

  int get positionMs => _micros(properties['Position']) ~/ 1000;

  String? get artUrl => switch (_string(_metadata['mpris:artUrl'])) {
    '' => null,
    final url => url,
  };

  /// A link others can open, such as an open.spotify.com URL. Local files
  /// stay private.
  String? get contentUri {
    final url = _string(_metadata['xesam:url']);
    final isLink =
        url.startsWith('https://') ||
        url.startsWith('http://') ||
        url.startsWith('spotify:');
    if (!isLink) {
      return null;
    }

    return url;
  }

  PlayerStatus get status => switch (_string(properties['PlaybackStatus'])) {
    'Playing' => .playing,
    'Paused' => .paused,
    _ => .stopped,
  };

  double get rate => switch (properties['Rate']) {
    final DBusDouble rate when rate.value > 0 => rate.value,
    _ => 1,
  };

  double get volume => switch (properties['Volume']) {
    final DBusDouble volume => volume.value.clamp(0, 1).toDouble(),
    _ => -1,
  };

  List<PlayerAction> get actions => [
    if (_flag('CanPlay')) .play,
    if (_flag('CanPause')) .pause,
    if (_flag('CanPlay') || _flag('CanPause')) .toggle,
    if (_flag('CanGoNext')) .next,
    if (_flag('CanGoPrevious')) .previous,
    if (_flag('CanSeek')) .seek,
    if (properties['Volume'] is DBusDouble) .setVolume,
  ];

  /// The player as a [PlayerInfo], or null when it has nothing loaded.
  PlayerInfo? toPlayer({
    required String busName,
    required String appName,
    required String appId,
    required int nowMs,
    required int lastActiveAtMs,
  }) {
    if (title.isEmpty || status == .stopped) {
      return null;
    }

    return PlayerInfo(
      id: busName,
      appId: appId,
      appName: appName,
      title: title,
      artist: artist,
      album: album,
      durationMs: durationMs,
      positionMs: positionMs,
      positionAtMs: nowMs,
      status: status,
      playbackRate: rate,
      contentUri: contentUri,
      lastActiveAtMs: lastActiveAtMs,
      actions: actions,
      volume: volume,
    );
  }

  bool _flag(String name) => switch (properties[name]) {
    final DBusBoolean flag => flag.value,
    _ => false,
  };

  static String _string(DBusValue? value) => switch (value) {
    final DBusString text => text.value,
    final DBusVariant variant => _string(variant.value),
    _ => '',
  };

  static int _micros(DBusValue? value) => switch (value) {
    final DBusInt64 number => number.value,
    final DBusUint64 number => number.value,
    final DBusInt32 number => number.value,
    final DBusUint32 number => number.value,
    final DBusVariant variant => _micros(variant.value),
    _ => 0,
  };

  static Map<String, DBusValue> _stringKeyed(DBusDict dict) => {
    for (final MapEntry(:key, :value) in dict.children.entries)
      if (key case final DBusString name)
        name.value: switch (value) {
          final DBusVariant variant => variant.value,
          _ => value,
        },
  };
}
