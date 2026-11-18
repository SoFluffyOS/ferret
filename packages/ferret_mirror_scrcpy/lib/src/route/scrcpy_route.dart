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
///
/// [toolsDirectory] is where downloaded platform tools and scrcpy's server
/// go; it defaults to a `mirror_scrcpy` folder in the app support folder.
class ScrcpyRoute implements ToolInstaller {
  ScrcpyRoute({
    Future<Directory> Function()? toolsDirectory,
    Future<AdbBridge?> Function()? findAdb,
    Map<String, String>? environment,
    AdbLocator? locator,
    AdbHostClient? hostAdb,
    ScrcpyServerBundle? serverBundle,
    String? operatingSystem,
    this.pollInterval = const Duration(seconds: 2),
  }) : _toolsDirectory = toolsDirectory ?? _defaultToolsDirectory,
       _findAdbOverride = findAdb,
       _hostAdb = hostAdb ?? AdbHostClient(),
       _environment = environment ?? Platform.environment,
       _locatorOverride = locator,
       _operatingSystem = operatingSystem ?? Platform.operatingSystem {
    _installer = AdbInstaller(
      directory: _toolsDirectory,
      operatingSystem: _operatingSystem,
    );
    _serverBundle =
        serverBundle ?? ScrcpyServerBundle(directory: _toolsDirectory);
    _changes = .broadcast(onListen: _startPolling, onCancel: _stopPolling);
  }

  static const String routeId = 'adb';

  /// [RouteNeedsSetup.detail] with [RouteSetup.installTool]: there is no
  /// adb on this computer.
  static const String needsAdb = 'adb';

  /// [RouteNeedsSetup.detail] with [RouteSetup.installTool]: this app isn't
  /// allowed to start adb, as inside the macOS App Sandbox. The user has
  /// to start it: open Android Studio, or run `adb start-server` in a
  /// terminal. Installing anything from here wouldn't help.
  static const String needsAdbStarted = 'adb start-server';

  static const String _sandboxVariable = 'APP_SANDBOX_CONTAINER_ID';
  static const Set<String> _computers = {'macos', 'windows', 'linux'};

  /// How often `adb devices` is asked while someone listens to [targets].
  final Duration pollInterval;

  final Future<Directory> Function() _toolsDirectory;
  final Future<AdbBridge?> Function()? _findAdbOverride;
  final AdbHostClient _hostAdb;
  final Map<String, String> _environment;
  final AdbLocator? _locatorOverride;
  final String _operatingSystem;
  late final AdbInstaller _installer;
  late final ScrcpyServerBundle _serverBundle;
  late final StreamController<List<MirrorTarget>> _changes;
  final Set<ScrcpyFeed> _feeds = {};

  AdbClient? _program;
  final Set<String> _blockedPrograms = {};
  Timer? _poll;
  List<MirrorTarget>? _lastTargets;
  bool _isPolling = false;

  @override
  String get id => routeId;

  bool get isSupported => _computers.contains(_operatingSystem);

  /// Whether this app runs in the macOS App Sandbox. There it can talk to
  /// an adb server that is already running, but can't start adb itself:
  /// not the user's own, and not one it downloaded.
  bool get isSandboxed => _environment.containsKey(_sandboxVariable);

  /// Whether [installAdb] can help here. Offer the download only when it
  /// does.
  bool get canInstallAdb => isSupported && !isSandboxed;

  @override
  bool get canInstallTool => canInstallAdb;

  @override
  String get toolNotStartedDetail => needsAdbStarted;

  @override
  Future<void> installTool() => installAdb();

  @override
  Future<RouteStatus> status() async {
    if (!isSupported) {
      return const RouteUnsupported();
    }

    final adb = await _locateAdb();
    if (adb == null) {
      return RouteNeedsSetup(.installTool, detail: _missingAdbDetail);
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
      serverBundle: _serverBundle,
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

  /// Downloads Android's platform-tools (adb) from Google into Ferret's
  /// own folder, checked against a pinned SHA-256.
  ///
  /// This is the only thing in this package that reaches the internet.
  /// Call it from a button the user pressed, whose text says it downloads
  /// Android's platform tools from Google. Never call it on your own.
  /// Throws a `DownloadException` when it fails.
  ///
  /// Throws a [StateError] where [canInstallAdb] is false.
  Future<void> installAdb() async {
    if (!canInstallAdb) {
      throw StateError('A downloaded adb cannot be run from here');
    }

    _program = AdbClient(await _installer.install());
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
    Future<AdbResult> Function(AdbBridge adb) command,
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

  /// adb's server when one is running, which needs no program and works
  /// inside a sandbox. The `adb` program otherwise: its first command
  /// starts the server, so the next call finds it.
  Future<AdbBridge?> _locateAdb() async {
    if (_findAdbOverride case final findAdb?) {
      return findAdb();
    }

    if (await _hostAdb.isRunning()) {
      return _hostAdb;
    }

    if (_program case final known?) {
      return known;
    }

    final locator =
        _locatorOverride ??
        AdbLocator(
          operatingSystem: _operatingSystem,
          environment: _environment,
          extraDirectories: [await _installer.installDirectory()],
        );
    for (final executable in locator.findAll()) {
      if (_blockedPrograms.contains(executable)) {
        continue;
      }

      final program = AdbClient(executable);
      if (await program.canRun()) {
        return _program = program;
      }

      _blockedPrograms.add(executable);
    }

    return null;
  }

  String get _missingAdbDetail {
    if (isSandboxed || _blockedPrograms.isNotEmpty) {
      return needsAdbStarted;
    }

    return needsAdb;
  }

  Future<List<AdbDevice>> _devicesOf(AdbBridge adb) async {
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

  static Future<Directory> _defaultToolsDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'mirror_scrcpy'));
  }
}
