import 'dart:async';

import 'package:engine/engine.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:power/models/models.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The engine side of Power-ups. It sends nothing to other devices: its job
/// is to remember which tiers the user turned on and hand that to
/// [PowerCapabilities], which the other features ask for abilities.
class PowerFeature extends Feature {
  PowerFeature({PowerCapabilities Function()? capabilities})
    : _createCapabilities = capabilities ?? PowerCapabilities.new;

  static const featureId = 'power';

  final PowerCapabilities Function() _createCapabilities;

  /// Made on first use, once the app's platform channels are up. By
  /// default the instance every feature shares.
  late final PowerCapabilities capabilities = _createCapabilities();
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Future<void> _ready = Future.value();

  @override
  String get id => featureId;

  PowerSettings get settings => PowerSettings(host.settings);

  PowerStatus get status => capabilities.status;

  PowerTier get tier => capabilities.activeTier;

  /// Fires when the phone's state, the active tier or a setting changes.
  Stream<void> get changes => _changes.stream;

  /// Done once the saved choices are applied and the phone was read. With
  /// root turned on this can wait on the root manager, so starting the
  /// engine doesn't wait for it.
  Future<void> get ready => _ready;

  @override
  Future<void> onStart() async {
    _subscriptions.addAll([
      capabilities.statusChanges.listen((_) => _changes.add(null)),
      capabilities.tierChanges.listen((_) => _changes.add(null)),
      settings.changes.listen((_) => _changes.add(null)),
    ]);

    _ready = capabilities
        .configure(shizuku: settings.shizukuEnabled, root: settings.rootEnabled)
        .then((_) => _changes.add(null));
    unawaited(_ready);
  }

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;

  /// Shows Shizuku's dialog. A yes turns the tier on and is remembered.
  Future<bool> allowShizuku() async {
    final allowed = await capabilities.authorizeShizuku();
    if (allowed) {
      await settings.setShizukuEnabled(true);
    }

    return allowed;
  }

  Future<void> stopUsingShizuku() async {
    capabilities.setShizukuEnabled(false);
    await settings.setShizukuEnabled(false);
  }

  /// Asks the root manager. A yes turns the tier on and is remembered.
  Future<bool> useRoot() async {
    final allowed = await capabilities.enableRoot();
    await settings.setRootEnabled(allowed);
    return allowed;
  }

  Future<void> stopUsingRoot() async {
    capabilities.disableRoot();
    await settings.setRootEnabled(false);
  }
}
