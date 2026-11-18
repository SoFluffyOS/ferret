import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/ferret_route.dart';

/// Every way a screen can arrive on this computer, and which one to use
/// for a device. Ferret's own route is always there. The cable routes run
/// while "Look for phones on a cable" is on; each receiver listens while
/// its switch is on, or for a moment after its owner asked for it.
class MirrorRoutes {
  MirrorRoutes({
    required this.ferret,
    required MirroringSettings settings,
    required String Function() receiverName,
    Map<String, String> Function()? pairedPhones,
    List<MirrorRoute> routes = const [],
    List<MirrorReceiver> receivers = const [],
    DateTime Function()? clock,
    this.askTimeout = const Duration(seconds: 30),
    this.armTime = const Duration(minutes: 2),
  }) : _settings = settings,
       _clock = clock ?? DateTime.now,
       _receiverName = receiverName,
       _pairedPhones = pairedPhones ?? _noPhones,
       _routes = routes,
       _receivers = receivers;

  final FerretRoute ferret;

  /// Whether a device that started by itself is on screen right now. Its
  /// receiver keeps listening until that is over, whatever else says stop.
  bool Function() isShowingIncoming = _never;

  /// How long a device's question waits for its answer before it is a no.
  final Duration askTimeout;

  /// How long the receivers listen after [armReceivers].
  final Duration armTime;

  final MirroringSettings _settings;
  final String Function() _receiverName;

  /// The paired Android devices a cable could also reach, name by id.
  final Map<String, String> Function() _pairedPhones;
  final DateTime Function() _clock;
  final List<IncomingRequest> _requests = [];
  final List<MirrorRoute> _routes;
  final List<MirrorReceiver> _receivers;
  final StreamController<void> _changes = .broadcast();
  final StreamController<MirrorFeed> _incoming = .broadcast();
  final Map<String, List<MirrorTarget>> _targets = {};
  final List<StreamSubscription<Object?>> _listening = [];
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Timer? _armTimer;
  DateTime? _armedUntil;
  bool _running = false;
  bool _started = false;
  bool _disposed = false;

  /// The app plugged in a way to show a phone on a cable.
  bool get hasCable => _routes.isNotEmpty;

  /// The cable routes look for phones right now.
  bool get cableOn => hasCable && _settings.lookForCable;

  bool get hasReceivers => _receivers.isNotEmpty;

  /// Fires when [targets], [requests], who is connected or what listens
  /// changes.
  Stream<void> get changes => _changes.stream;

  /// A device started showing its screen here, through a receiver.
  Stream<MirrorFeed> get incoming => _incoming.stream;

  /// The phones a cable reaches that aren't paired with Ferret. A paired
  /// one is found through [cableTargetFor] instead.
  List<MirrorTarget> get targets => [
    for (final target in _cableTargets)
      if (_pairedIdOf(target) == null) target,
  ];

  /// The cable's way to the paired device [deviceId]: a phone it found
  /// that says it is that device, or one with its name, the one on a real
  /// cable before the same phone over Wi-Fi debugging. With [orOnlyOne],
  /// the single phone on a cable counts too, for an owner who just
  /// followed the steps to plug that device in.
  MirrorTarget? cableTargetFor(String deviceId, {bool orOnlyOne = false}) {
    final matches = [
      for (final target in _cableTargets)
        if (_pairedIdOf(target) == deviceId) target,
    ];
    for (final target in matches) {
      if (!target.wireless) {
        return _claim(target, deviceId);
      }
    }

    if (matches.isNotEmpty) {
      return _claim(matches.first, deviceId);
    }

    final unpaired = targets;
    if (!orOnlyOne || unpaired.length != 1) {
      return null;
    }

    return _claim(unpaired.single, deviceId);
  }

  /// The way to show the paired device [deviceId] right now. Ferret
  /// first, because the phone's owner is asked there. The cable when
  /// Ferret can't reach the phone, or when [preferControl] says the
  /// person asked to click and type.
  MirrorTarget bestTargetFor(String deviceId, {bool preferControl = false}) {
    final cable = cableTargetFor(deviceId);
    if (cable != null && (preferControl || !ferret.isConnected(deviceId))) {
      return cable;
    }

    return ferret.targetFor(deviceId);
  }

  /// Whether [target]'s route sees the device right now.
  bool isReachable(MirrorTarget target) {
    if (target.routeId == ferret.id) {
      return ferret.isConnected(target.id);
    }

    return _cableTargets.contains(target);
  }

  /// The receivers the app plugged in, and whether each listens.
  List<ReceiverSwitch> get receivers => [
    for (final receiver in _receivers)
      ReceiverSwitch(receiverId: receiver.id, on: _isOn(receiver)),
  ];

  /// Until when the receivers listen because their owner asked to show a
  /// device, whatever their switches say. Null when nobody asked.
  DateTime? get armedUntil => _armedUntil;

  /// The devices asking to show their screen here right now.
  List<IncomingRequest> get requests => List.of(_requests);

  Future<void> setReceiverOn(String receiverId, bool value) =>
      _settings.setReceiverOn(receiverId, value);

  /// Makes every receiver listen for [armTime], for an owner who is about
  /// to pick this computer on their device.
  Future<void> armReceivers() async {
    _armedUntil = _clock().add(armTime);
    _armTimer?.cancel();
    _armTimer = Timer(armTime, () => unawaited(disarmReceivers()));
    await _listenAll();
    _emit();
  }

  Future<void> disarmReceivers() async {
    if (_armedUntil == null) {
      return;
    }

    _armTimer?.cancel();
    _armTimer = null;
    _armedUntil = null;
    await _listenAll();
    _emit();
  }

  /// The owner's answer to [request].
  void answer(IncomingRequest request, {required bool allow}) {
    request.complete(allow);
    if (_requests.remove(request)) {
      _emit();
    }
  }

  MirrorRoute? routeFor(MirrorTarget target) {
    if (target.routeId == ferret.id) {
      return ferret;
    }

    if (!_running) {
      return null;
    }

    for (final route in _routes) {
      if (route.id == target.routeId) {
        return route;
      }
    }

    return null;
  }

  /// Starts following who is connected and the settings.
  void start() {
    _started = true;
    _subscriptions
      ..add(ferret.targets.listen((_) => _emit()))
      ..add(
        _settings.changes
            .where(
              (key) =>
                  key == MirroringSettings.lookForCableKey ||
                  key.startsWith(MirroringSettings.receiverKeyPrefix),
            )
            .listen((_) => unawaited(_apply())),
      );
    for (final receiver in _receivers) {
      _subscriptions.add(
        receiver.incoming.listen((feed) {
          if (!_incoming.isClosed) {
            _incoming.add(feed);
          }
        }),
      );
    }

    unawaited(_apply());
  }

  /// Where showing a phone over a cable stands, asked fresh. Null where
  /// no cable route can work on this computer.
  Future<CableSetup?> cableSetup() async {
    CableSetup? missing;
    for (final route in _routes) {
      final status = await statusOf(route);
      if (status is RouteReady) {
        return .ready;
      }

      if (status case RouteNeedsSetup(:final step, :final detail)) {
        missing ??= CableSetup(
          step: step,
          detail: detail,
          help: _helpFor(route, step, detail),
        );
      }
    }

    return missing;
  }

  /// Downloads the tool the cable routes are missing. Only for a button
  /// the owner pressed. Throws when the download fails.
  Future<void> installTool() async {
    for (final route in _routes) {
      if (route is ToolInstaller && route.canInstallTool) {
        await route.installTool();
      }
    }
  }

  /// Where [route] stands, or unsupported when it can't even say.
  Future<RouteStatus> statusOf(MirrorRoute route) =>
      _statusOf(route.id, route.status);

  Future<void> dispose() async {
    _disposed = true;
    _armTimer?.cancel();
    for (final request in List.of(_requests)) {
      request.complete(false);
    }

    _requests.clear();
    for (final subscription in [..._subscriptions, ..._listening]) {
      unawaited(subscription.cancel());
    }

    for (final receiver in _receivers) {
      await _guard(receiver.id, receiver.dispose);
    }

    for (final route in _routes) {
      await _guard(route.id, route.dispose);
    }

    await ferret.dispose();
    await _changes.close();
    await _incoming.close();
  }

  /// Looks again at which receivers should listen, such as after a device
  /// that started by itself is done.
  Future<void> refreshReceivers() => _listenAll();

  static Map<String, String> _noPhones() => const {};

  static bool _never() => false;

  /// Everything the cable routes found. A phone two routes reach shows
  /// once.
  List<MirrorTarget> get _cableTargets {
    final seen = <String>{};
    final merged = <MirrorTarget>[];
    for (final route in _routes) {
      for (final target in _targets[route.id] ?? const <MirrorTarget>[]) {
        final deviceId = target.ferretDeviceId;
        if (deviceId != null && !seen.add(deviceId)) {
          continue;
        }

        merged.add(target);
      }
    }

    return merged;
  }

  /// The paired device [target] is: the one it names, or the only paired
  /// phone called the same. A phone plugged in that also has Wi-Fi
  /// debugging on shows up twice under one name, and is one phone.
  String? _pairedIdOf(MirrorTarget target) {
    final phones = _pairedPhones();
    final deviceId = target.ferretDeviceId;
    if (deviceId != null) {
      return switch (phones.containsKey(deviceId)) {
        true => deviceId,
        false => null,
      };
    }

    final name = _plain(target.name);
    final sameName = [
      for (final MapEntry(:key, :value) in phones.entries)
        if (_plain(value) == name) key,
    ];
    if (sameName.length != 1) {
      return null;
    }

    return sameName.single;
  }

  String _plain(String name) => name.trim().toLowerCase();

  /// [target] as the paired device [deviceId], under the name it is
  /// known by here.
  MirrorTarget _claim(MirrorTarget target, String deviceId) => MirrorTarget(
    routeId: target.routeId,
    id: target.id,
    name: _pairedPhones()[deviceId] ?? target.name,
    ferretDeviceId: deviceId,
    wireless: target.wireless,
  );

  Future<void> _apply() async {
    if (_disposed) {
      return;
    }

    final wanted = cableOn;
    if (wanted != _running) {
      _running = wanted;
      _followRoutes(wanted);
    }

    await _listenAll();
    _emit();
  }

  void _followRoutes(bool follow) {
    if (!follow) {
      for (final subscription in _listening) {
        unawaited(subscription.cancel());
      }

      _listening.clear();
      _targets.clear();
      return;
    }

    for (final route in _routes) {
      _listening.add(
        route.targets.listen(
          (targets) {
            _targets[route.id] = targets;
            _emit();
          },
          onError: (Object error) =>
              printWarning('Listing screens through ${route.id} failed', error),
        ),
      );
    }
  }

  Future<void> _listenAll() async {
    if (!_started || _disposed) {
      return;
    }

    for (final receiver in _receivers) {
      await _listen(receiver);
    }

    if (_receivers.any((receiver) => receiver.isListening)) {
      return;
    }

    for (final request in List.of(_requests)) {
      answer(request, allow: false);
    }
  }

  /// Starts [receiver] once it should listen and nothing is missing for
  /// it, and stops one that shouldn't any more.
  Future<void> _listen(MirrorReceiver receiver) async {
    final wanted = _isOn(receiver) || _armedUntil != null;
    if (!wanted) {
      if (receiver.isListening && !isShowingIncoming()) {
        await _guard(receiver.id, receiver.stop);
      }

      return;
    }

    if (receiver.isListening) {
      return;
    }

    final status = await _statusOf(receiver.id, receiver.status);
    if (status is! RouteReady || _disposed) {
      return;
    }

    await _guard(
      receiver.id,
      () => receiver.start(
        _receiverName(),
        allow: (deviceName) => _ask(receiver.id, deviceName),
      ),
    );
  }

  bool _isOn(MirrorReceiver receiver) => _settings.receiverOn(
    receiver.id,
    byDefault: receiver.listensByDefault,
  );

  /// Puts a device's question in front of the owner. No answer within
  /// [askTimeout] is a no.
  Future<bool> _ask(String receiverId, String deviceName) async {
    if (_disposed) {
      return false;
    }

    final askedAt = _clock();
    final request = IncomingRequest(
      receiverId: receiverId,
      deviceName: deviceName,
      askedAt: askedAt,
      deadline: askedAt.add(askTimeout),
    );
    _requests.add(request);
    _emit();
    final timeout = Timer(askTimeout, () => answer(request, allow: false));
    final allowed = await request.answer;
    timeout.cancel();
    return allowed;
  }

  SetupHelp _helpFor(MirrorRoute route, RouteSetup step, String? detail) {
    if (step != .installTool || route is! ToolInstaller) {
      return .none;
    }

    if (detail == route.toolNotStartedDetail) {
      return .startTool;
    }

    if (route.canInstallTool) {
      return .download;
    }

    return .none;
  }

  Future<RouteStatus> _statusOf(
    String routeId,
    Future<RouteStatus> Function() status,
  ) async {
    try {
      return await status();
    } on Object catch (error) {
      printWarning('Asking $routeId where it stands failed', error);
      return const RouteUnsupported();
    }
  }

  Future<void> _guard(String routeId, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      printWarning('Mirroring through $routeId failed', error);
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
