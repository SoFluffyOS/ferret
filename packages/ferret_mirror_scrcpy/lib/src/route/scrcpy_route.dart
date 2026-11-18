import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb.dart';
import 'package:ferret_mirror_scrcpy/src/route/scrcpy_feed.dart';
import 'package:ferret_mirror_scrcpy/src/server/server.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Shows an Android device's screen on a computer through adb, with
/// scrcpy's own server doing the capture on the device. The device needs
/// USB or wireless debugging turned on, and nothing installed: no root, no
/// Shizuku, no Ferret.
///
/// Computers only. On a phone, [status] is [RouteUnsupported].
class ScrcpyRoute implements MirrorRoute {
  ScrcpyRoute({
    Future<Directory> Function()? supportDirectory,
    Future<AdbClient?> Function()? findAdb,
    String? operatingSystem,
    this.pollInterval = const Duration(seconds: 2),
  }) : _supportDirectory = supportDirectory ?? _defaultSupportDirectory,
       _findAdbOverride = findAdb,
       _operatingSystem = operatingSystem ?? Platform.operatingSystem {
    _installer = AdbInstaller(
      directory: _supportDirectory,
      operatingSystem: _operatingSystem,
    );
    _serverCache = ScrcpyServerCache(directory: _supportDirectory);
    _changes = .broadcast(onListen: _startPolling, onCancel: _stopPolling);
  }

  static const String routeId = 'adb';
  static const Set<String> _computers = {'macos', 'windows', 'linux'};

  /// How often `adb devices` is asked while someone listens to [targets].
  final Duration pollInterval;

  final Future<Directory> Function() _supportDirectory;
  final Future<AdbClient?> Function()? _findAdbOverride;
  final String _operatingSystem;
  late final AdbInstaller _installer;
  late final ScrcpyServerCache _serverCache;
  late final StreamController<List<MirrorTarget>> _changes;
  final Set<ScrcpyFeed> _feeds = {};

  AdbClient? _adb;
  Timer? _poll;
  List<MirrorTarget>? _lastTargets;
  bool _isPolling = false;

  @override
  String get id => routeId;

  bool get isSupported => _computers.contains(_operatingSystem);

  @override
  Future<RouteStatus> status() async {
    if (!isSupported) {
      return const RouteUnsupported();
    }

    final adb = await _locateAdb();
    if (adb == null) {
      return const RouteNeedsSetup(.installTool, detail: 'adb');
    }

    final devices = await _devicesOf(adb);
    if (devices.any((device) => device.state == .ready)) {
      return const RouteReady();
    }

    for (final device in devices) {
      if (device.state == .unauthorized) {
        return RouteNeedsSetup(.authorizeComputer, detail: device.name);
      }
    }

    return const RouteNeedsSetup(.enableDebugging);
  }

  /// The devices that are ready to show. A device that hasn't allowed this
  /// computer yet isn't one: [status] and [devices] tell about it.
  @override
  Stream<List<MirrorTarget>> get targets {
    return .multi((listener) {
      if (_lastTargets case final known?) {
        listener.add(known);
      }

      final subscription = _changes.stream.listen(
        listener.addSync,
        onDone: listener.closeSync,
      );
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Future<MirrorFeed> open(MirrorTarget target, FeedOptions options) async {
    final adb = await _locateAdb();
    if (adb == null) {
      throw StateError('adb is not installed: check status() first');
    }

    final feed = ScrcpyFeed(
      target: target,
      adb: adb,
      serverCache: _serverCache,
      options: options,
    );
    _feeds.add(feed);
    return feed;
  }

  @override
  Future<void> dispose() async {
    _stopPolling();
    await Future.wait(_feeds.map((feed) => feed.stop()));
    _feeds.clear();
    await _changes.close();
  }

  /// Downloads Google's platform-tools for this computer into Ferret's own
  /// folder, checked against a pinned SHA-256. For when [status] says
  /// [RouteSetup.installTool]. Throws a `DownloadException` when it fails.
  Future<void> installAdb() async {
    _adb = AdbClient(await _installer.install());
  }

  /// Every device adb sees, including the ones still to authorize, so the
  /// UI can say "Tap Allow on Pixel".
  Future<List<AdbDevice>> devices() async {
    if (!isSupported) {
      return const [];
    }

    final adb = await _locateAdb();
    if (adb == null) {
      return const [];
    }

    return _devicesOf(adb);
  }

  /// Pairs with a device over Wi-Fi (Android 11 and later): [address] and
  /// [code] are the ones under Wireless debugging → Pair device with
  /// pairing code. Follow with [connect].
  Future<AdbResult> pair(String address, String code) =>
      _withAdb((adb) => adb.pair(address, code));

  /// Connects to a paired device at the address on its Wireless debugging
  /// screen. It then shows up in [targets].
  Future<AdbResult> connect(String address) =>
      _withAdb((adb) => adb.connect(address));

  Future<void> disconnect(String address) async {
    await _withAdb((adb) async {
      await adb.disconnect(address);
      return const AdbResult(succeeded: true, message: '');
    });
  }

  Future<AdbResult> _withAdb(
    Future<AdbResult> Function(AdbClient adb) command,
  ) async {
    final adb = await _locateAdb();
    if (adb == null) {
      return const AdbResult(succeeded: false, message: 'adb is not installed');
    }

    try {
      return await command(adb);
    } on AdbException catch (error) {
      return AdbResult(succeeded: false, message: error.message);
    }
  }

  Future<AdbClient?> _locateAdb() async {
    if (_adb case final known?) {
      return known;
    }

    if (_findAdbOverride case final findAdb?) {
      return _adb = await findAdb();
    }

    final locator = AdbLocator(
      operatingSystem: _operatingSystem,
      extraDirectories: [await _installer.installDirectory()],
    );
    final executable = locator.find();
    if (executable == null) {
      return null;
    }

    return _adb = AdbClient(executable);
  }

  Future<List<AdbDevice>> _devicesOf(AdbClient adb) async {
    try {
      return await adb.devices();
    } on AdbException catch (error) {
      printWarning('adb devices failed: ${error.message}');
      return const [];
    }
  }

  void _startPolling() {
    unawaited(_pollOnce());
    _poll = Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _pollOnce() async {
    if (_isPolling) {
      return;
    }

    _isPolling = true;
    final found = await _readyTargets();
    _isPolling = false;

    if (_changes.isClosed || _sameTargets(found, _lastTargets)) {
      return;
    }

    _lastTargets = found;
    _changes.add(found);
  }

  Future<List<MirrorTarget>> _readyTargets() async {
    final known = await devices();
    return [
      for (final device in known)
        if (device.state == AdbDeviceState.ready)
          MirrorTarget(
            routeId: routeId,
            id: device.serial,
            name: device.name,
            wireless: device.isWireless,
          ),
    ];
  }

  static bool _sameTargets(
    List<MirrorTarget> found,
    List<MirrorTarget>? known,
  ) {
    if (known == null || known.length != found.length) {
      return false;
    }

    for (var index = 0; index < found.length; index++) {
      final isSame =
          found[index] == known[index] &&
          found[index].name == known[index].name;
      if (!isSame) {
        return false;
      }
    }

    return true;
  }

  static Future<Directory> _defaultSupportDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'mirror_scrcpy'));
  }
}
