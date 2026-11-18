import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/ferret_route.dart';

/// Every way a screen can arrive on this computer. Ferret's own route is
/// always there. The others, and the receivers other devices start
/// themselves, only run while "More ways" is on in settings.
class MirrorRoutes {
  MirrorRoutes({
    required this.ferret,
    required MirroringSettings settings,
    required String Function() receiverName,
    List<MirrorRoute> routes = const [],
    List<MirrorReceiver> receivers = const [],
  }) : _settings = settings,
       _receiverName = receiverName,
       _routes = routes,
       _receivers = receivers;

  final FerretRoute ferret;

  final MirroringSettings _settings;
  final String Function() _receiverName;
  final List<MirrorRoute> _routes;
  final List<MirrorReceiver> _receivers;
  final StreamController<void> _changes = .broadcast();
  final StreamController<MirrorFeed> _incoming = .broadcast();
  final Map<String, List<MirrorTarget>> _targets = {};
  final Map<String, RouteNotice> _notices = {};
  final List<StreamSubscription<Object?>> _listening = [];
  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<MirrorTarget> _ferretTargets = const [];
  bool _running = false;
  bool _disposed = false;

  /// Whether the app plugged in anything besides Ferret's own route.
  bool get hasMoreWays => _routes.isNotEmpty || _receivers.isNotEmpty;

  /// The other ways are turned on, and there are some.
  bool get moreWaysOn => hasMoreWays && _settings.moreWays;

  /// Fires when [targets] or [notices] change.
  Stream<void> get changes => _changes.stream;

  /// A device started showing its screen here, through a receiver.
  Stream<MirrorFeed> get incoming => _incoming.stream;

  /// The devices the other routes can show right now. A phone two routes
  /// reach shows once, and one Ferret itself can show isn't listed at all:
  /// its own route is the one used.
  List<MirrorTarget> get targets {
    final seen = {for (final target in _ferretTargets) target.ferretDeviceId};
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

  /// Another way to the paired device [deviceId], when Ferret's own route
  /// can't show it.
  MirrorTarget? targetForDevice(String deviceId) {
    for (final target in targets) {
      if (target.ferretDeviceId == deviceId) {
        return target;
      }
    }

    return null;
  }

  /// What the other ways still need before they work here.
  List<RouteNotice> get notices => List.of(_notices.values);

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

  /// Starts following Ferret's own targets and the setting.
  void start() {
    _subscriptions
      ..add(
        ferret.targets.listen((targets) {
          _ferretTargets = targets;
          _emit();
        }),
      )
      ..add(
        _settings.changes
            .where((key) => key == MirroringSettings.moreWaysKey)
            .listen((_) => unawaited(_apply())),
      );
    unawaited(_apply());
  }

  /// Asks every route again where it stands, such as after the owner did
  /// a setup step.
  Future<void> refresh() async {
    if (!_running) {
      return;
    }

    for (final route in _routes) {
      _note(route.id, await _statusOf(route.id, route.status));
    }

    for (final receiver in _receivers) {
      await _listen(receiver);
    }

    _emit();
  }

  /// Where [route] stands, or unsupported when it can't even say.
  Future<RouteStatus> statusOf(MirrorRoute route) =>
      _statusOf(route.id, route.status);

  Future<void> dispose() async {
    _disposed = true;
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

  Future<void> _apply() async {
    final wanted = moreWaysOn;
    if (wanted == _running || _disposed) {
      return;
    }

    _running = wanted;
    if (!wanted) {
      await _pause();
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

    for (final receiver in _receivers) {
      _listening.add(
        receiver.incoming.listen((feed) {
          if (!_incoming.isClosed) {
            _incoming.add(feed);
          }
        }),
      );
    }

    await refresh();
  }

  Future<void> _pause() async {
    for (final subscription in _listening) {
      unawaited(subscription.cancel());
    }

    _listening.clear();
    _targets.clear();
    _notices.clear();
    for (final receiver in _receivers) {
      await _guard(receiver.id, receiver.stop);
    }

    _emit();
  }

  /// Starts [receiver] once nothing is missing for it.
  Future<void> _listen(MirrorReceiver receiver) async {
    final status = await _statusOf(receiver.id, receiver.status);
    _note(receiver.id, status);
    if (status is! RouteReady || receiver.isListening || !_running) {
      return;
    }

    await _guard(receiver.id, () => receiver.start(_receiverName()));
  }

  void _note(String routeId, RouteStatus status) {
    if (status case RouteNeedsSetup(:final step, :final detail)) {
      _notices[routeId] = RouteNotice(
        routeId: routeId,
        step: step,
        detail: detail,
      );
      return;
    }

    _notices.remove(routeId);
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
