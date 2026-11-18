import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb.dart';
import 'package:ferret_mirror_scrcpy/src/protocol/protocol.dart';
import 'package:ferret_mirror_scrcpy/src/route/scrcpy_control.dart';
import 'package:ferret_mirror_scrcpy/src/route/scrcpy_sockets.dart';
import 'package:ferret_mirror_scrcpy/src/server/server.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// One Android device's screen, encoded on the device by scrcpy's server
/// and read here through adb.
///
/// The device's owner isn't asked again: allowing this computer to debug
/// the device was the question. So there is never a [FeedWaiting].
class ScrcpyFeed implements MirrorFeed {
  ScrcpyFeed({
    required this.target,
    required AdbBridge adb,
    required ScrcpyServerBundle serverBundle,
    required FeedOptions options,
    Random? random,
  }) : _adb = adb,
       _serverBundle = serverBundle,
       _options = options,
       _serverOptions = .from(
         options,
         scid: (random ?? Random.secure()).nextInt(1 << 31),
       ),
       _assembler = .new(fps: options.maxFps) {
    _control = ScrcpyControl(_sendControl);
    unawaited(_start());
  }

  static const Duration _serverExitGrace = Duration(seconds: 1);

  @override
  final MirrorTarget target;

  final AdbBridge _adb;
  final ScrcpyServerBundle _serverBundle;
  final FeedOptions _options;
  final ScrcpyServerOptions _serverOptions;
  final H264FeedAssembler _assembler;
  final ScrcpyDemuxer _demuxer = .new();
  final StreamController<FeedEvent> _events = .new();
  late final ScrcpyControl _control;

  AdbShell? _server;
  ScrcpySockets? _sockets;
  StreamSubscription<Uint8List>? _videoSubscription;
  String _lastServerLine = '';
  bool _ended = false;

  @override
  Stream<FeedEvent> get events => _events.stream;

  @override
  MirrorControl? get control {
    if (!_options.control) {
      return null;
    }

    return _control;
  }

  /// The device's name as its scrcpy server reports it, once connected.
  String? deviceName;

  /// Restarts the device's encoder (scrcpy's "reset video"), which starts
  /// with a keyframe.
  @override
  Future<void> requestKeyframe() async =>
      _sendControl(ControlMessage.resetVideo());

  /// scrcpy's server takes its bitrate once, when it starts, so this does
  /// nothing. Open a new feed for another bitrate.
  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Future<void> stop() => _end(.stoppedHere);

  Future<void> _start() async {
    if (!_options.codecs.contains(MirrorCodec.h264)) {
      return _end(.noCodec);
    }

    try {
      final serverFile = await _serverBundle.ensure();
      await _launch(serverFile);
    } on ScrcpyServerException catch (error) {
      await _end(.failed, detail: error.message);
    } on AdbException catch (error) {
      await _end(.notConnected, detail: error.message);
    } on IOException catch (error) {
      await _end(.failed, detail: '$error');
    }
  }

  Future<void> _launch(File serverFile) async {
    final serial = target.id;
    await _adb.push(serial, serverFile, _serverOptions.devicePath);
    if (_ended) {
      return _removeServerFile();
    }

    final server = await _adb.startShell(serial, _serverOptions.shellCommand);
    _server = server;
    _watch(server);

    final sockets = await ScrcpySockets.connect(
      () => _adb.open(serial, _serverOptions.socketName),
      shouldGiveUp: () => _ended,
    );
    if (_ended) {
      sockets?.close();
      return _cleanUp();
    }

    if (sockets == null) {
      return _end(.failed, detail: 'No answer from scrcpy: $_lastServerLine');
    }

    _sockets = sockets;
    _videoSubscription = sockets.video.listen(
      _onVideo,
      onDone: () => unawaited(_end(.lostConnection)),
    );
  }

  /// Keeps the server's last words for a failure's detail, and ends the
  /// feed when the server ends first.
  void _watch(AdbShell server) {
    server.lines.listen((line) {
      if (line.trim().isNotEmpty) {
        _lastServerLine = line.trim();
      }
    }, onError: (Object _) {});
    unawaited(
      server.done.then((_) {
        final reason = switch (_sockets) {
          null => FeedEnd.failed,
          _ => FeedEnd.lostConnection,
        };
        return _end(reason, detail: 'scrcpy ended: $_lastServerLine');
      }),
    );
  }

  void _onVideo(Uint8List chunk) {
    try {
      _demuxer.add(chunk).forEach(_onPacket);
    } on FormatException catch (error) {
      unawaited(_end(.failed, detail: error.message));
    }
  }

  void _onPacket(ScrcpyPacket packet) {
    if (_ended) {
      return;
    }

    switch (packet) {
      case DeviceMetaPacket(:final deviceName):
        this.deviceName = deviceName;
      case CodecPacket(codecId: CodecPacket.h264):
        break;
      case CodecPacket(codecId: CodecPacket.disabled):
        unawaited(_end(.failed, detail: 'The device turned the video off'));
      case CodecPacket(codecId: CodecPacket.configurationError):
        unawaited(_end(.failed, detail: 'The device could not set up video'));
      case CodecPacket(:final codecId):
        unawaited(_end(.noCodec, detail: 'Codec ${codecId.toRadixString(16)}'));
      case SessionPacket(:final width, :final height):
        _control.setVideoSize(width, height);
      case MediaPacket():
        _assembler.add(packet).forEach(_events.add);
    }
  }

  void _sendControl(Uint8List message) {
    if (_ended) {
      return;
    }

    _sockets?.sendControl(message);
  }

  Future<void> _end(FeedEnd reason, {String? detail}) async {
    if (_ended) {
      return;
    }

    _ended = true;
    _events.add(FeedEnded(reason, detail: detail));
    await _cleanUp();
    unawaited(_events.close());
  }

  /// Closing the sockets is what tells the server to end. It gets a moment
  /// to do so and delete its own file, then it is cut off.
  Future<void> _cleanUp() async {
    await _videoSubscription?.cancel();
    _sockets?.close();

    if (_server case final server?) {
      _server = null;
      await server.done.timeout(_serverExitGrace, onTimeout: server.kill);
    }

    await _quietly(
      () => _adb.release(target.id, _serverOptions.socketName),
    );
    await _removeServerFile();
  }

  Future<void> _removeServerFile() => _quietly(
    () => _adb.shell(target.id, ['rm', '-f', _serverOptions.devicePath]),
  );

  static Future<void> _quietly(Future<Object?> Function() command) async {
    try {
      await command();
    } on AdbException catch (error) {
      printDebug('adb clean-up skipped: ${error.message}');
    }
  }
}
