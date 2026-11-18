import 'package:ferret_mirror_scrcpy/src/server/scrcpy_release.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// How one run of scrcpy's server is started on the device.
class ScrcpyServerOptions {
  const ScrcpyServerOptions({
    required this.scid,
    this.maxSize = 0,
    this.maxFps = 0,
    this.videoBitRate = 0,
  });

  factory ScrcpyServerOptions.from(FeedOptions options, {required int scid}) {
    return ScrcpyServerOptions(
      scid: scid,
      maxSize: options.maxSize,
      maxFps: options.maxFps,
      videoBitRate: options.bitrate,
    );
  }

  /// 31 random bits that name this run's socket on the device, so two runs
  /// on one device don't meet.
  final int scid;

  /// Each 0 leaves the server's own default.
  final int maxSize;
  final int maxFps;
  final int videoBitRate;

  String get scidHex => scid.toRadixString(16).padLeft(8, '0');

  /// The abstract socket the server listens on.
  String get socketName => 'scrcpy_$scidHex';

  /// Where the server's file goes on the device. One per run: the server
  /// deletes its own file when it ends.
  String get devicePath => '/data/local/tmp/ferret-scrcpy-server-$scidHex.jar';

  /// What goes after `adb shell`. Every key is one `Options.java` of the
  /// pinned version reads.
  ///
  /// The control socket is always open, because asking for a keyframe goes
  /// through it. The device's clipboard is never sent here on its own.
  List<String> get shellCommand => [
    'CLASSPATH=$devicePath',
    'app_process',
    '/',
    'com.genymobile.scrcpy.Server',
    ScrcpyRelease.version,
    'scid=$scidHex',
    'log_level=info',
    'tunnel_forward=true',
    'video_codec=h264',
    'audio=false',
    'control=true',
    'clipboard_autosync=false',
    if (maxSize > 0) 'max_size=$maxSize',
    if (maxFps > 0) 'max_fps=$maxFps',
    if (videoBitRate > 0) 'video_bit_rate=$videoBitRate',
  ];
}
