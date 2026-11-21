import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:core/core.dart';
import 'package:ferret_bonjour/src/bonjour_backend.dart';
import 'package:flutter/services.dart';

/// [BonjourBackend] on the system's own service browser through bonsoir:
/// NSNetService and NWBrowser on macOS and iOS, NsdManager on Android.
class BonsoirBackend implements BonjourBackend {
  const BonsoirBackend();

  /// What `kDNSServiceErr_PolicyDenied` reads as: the local network
  /// permission is off.
  static const _policyDenied = -65570;

  @override
  Future<BonjourOffer> offer({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
  }) async {
    final broadcast = BonsoirBroadcast(
      printLogs: false,
      service: BonsoirService(
        name: name,
        type: type,
        port: port,
        attributes: txt,
      ),
    );
    await broadcast.initialize();
    final offer = _BonsoirOffer(broadcast);
    await broadcast.start();
    return offer;
  }

  @override
  Future<BonjourBrowser> browse(String type) async {
    final discovery = BonsoirDiscovery(printLogs: false, type: type);
    await discovery.initialize();
    final browser = _BonsoirBrowser(discovery);
    await discovery.start();
    return browser;
  }

  static BonjourFailed failureOf(Object error) => switch (error) {
    PlatformException(:final details, :final code) => BonjourFailed(
      denied: details == _policyDenied,
      detail: '$code $details',
    ),
    _ => BonjourFailed(denied: false, detail: '${error.runtimeType}'),
  };
}

class _BonsoirOffer implements BonjourOffer {
  _BonsoirOffer(this._broadcast) {
    _subscription = _broadcast.eventStream?.listen(
      _onEvent,
      onError: (Object error) => _failures.add(BonsoirBackend.failureOf(error)),
    );
  }

  final BonsoirBroadcast _broadcast;
  final StreamController<BonjourFailed> _failures = .broadcast();
  StreamSubscription<BonsoirBroadcastEvent>? _subscription;

  @override
  Stream<BonjourFailed> get failures => _failures.stream;

  /// The system renamed the offer because the name is taken. Peers check
  /// that the name is the device id, so they would ignore it.
  void _onEvent(BonsoirBroadcastEvent event) {
    if (event is BonsoirBroadcastNameAlreadyExistsEvent) {
      printDebug('Bonjour: this device id is already offered here');
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    if (!_broadcast.isStopped) {
      await _broadcast.stop();
    }

    await _failures.close();
  }
}

class _BonsoirBrowser implements BonjourBrowser {
  _BonsoirBrowser(this._discovery) {
    _subscription = _discovery.eventStream?.listen(
      _onEvent,
      onError: (Object error) => _events.add(BonsoirBackend.failureOf(error)),
    );
  }

  final BonsoirDiscovery _discovery;
  final StreamController<BonjourEvent> _events = .broadcast();
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;

  @override
  Stream<BonjourEvent> get events => _events.stream;

  void _onEvent(BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent(:final service):
        unawaited(_resolve(service));
      case BonsoirDiscoveryServiceResolvedEvent(:final service) ||
          BonsoirDiscoveryServiceUpdatedEvent(:final service):
        if (service.hostAddresses.isEmpty) {
          return;
        }

        _events.add(
          BonjourFound(
            BonjourService(
              name: service.name,
              port: service.port,
              txt: service.attributes,
              addresses: service.hostAddresses,
            ),
          ),
        );
      case BonsoirDiscoveryServiceLostEvent(:final service):
        _events.add(BonjourLost(service.name));
      default:
        break;
    }
  }

  Future<void> _resolve(BonsoirService service) async {
    try {
      await _discovery.serviceResolver.resolveService(service);
    } on Object catch (error) {
      printDebug('Bonjour: could not resolve a device: $error');
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    if (!_discovery.isStopped) {
      await _discovery.stop();
    }

    await _events.close();
  }
}
