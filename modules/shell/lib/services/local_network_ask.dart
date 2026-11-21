import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:transport/transport.dart';

/// On an iPhone, iOS asks about the local network the first time Ferret
/// sends anything there. So discovery waits until the person reaches a
/// place that looks for devices (Home before anything is paired, Add a
/// device, Fix connection, a guest's file) and reads why. Once something
/// is paired, Ferret looks from launch: paired devices reconnect by their
/// known addresses, and the question was already answered.
class LocalNetworkAsk extends ChangeNotifier implements LocalNetworkGate {
  LocalNetworkAsk({
    required SettingsStore settings,
    required HeldDiscovery held,
    required bool Function() hasDevices,
    Stream<Object?>? deviceChanges,
    LocalNetworkProbe probe = const LocalNetworkProbe(),
  }) : _settings = settings,
       _held = held,
       _hasDevices = hasDevices,
       _probe = probe {
    _devices = deviceChanges?.listen((_) {
      if (_hasDevices()) {
        unawaited(allow());
      }
    });
  }

  /// Setting: the person read why and went on, so Ferret looks from launch.
  static const explainedKey = 'local_network.explained';

  final SettingsStore _settings;
  final HeldDiscovery _held;
  final bool Function() _hasDevices;
  final LocalNetworkProbe _probe;
  StreamSubscription<Object?>? _devices;

  /// Whether discovery may run from launch: the person went on before, or
  /// something is paired already.
  static bool releasedAtLaunch(
    SettingsStore settings, {
    required bool hasDevices,
  }) => hasDevices || (settings.get<bool>(explainedKey) ?? false);

  @override
  bool get needsAsk => !_held.isReleased;

  /// Lets discovery run, which is when iOS asks, and remembers it.
  Future<void> allow() async {
    if (_held.isReleased) {
      return;
    }

    await _settings.set(explainedKey, true);
    await _held.release();
    notifyListeners();
    // iOS shows its question now; the answer arrives when Ferret is back
    // in front, where the screens that show it check again.
    unawaited(refresh());
  }

  @override
  Future<bool> ask(BuildContext context) async {
    if (!needsAsk) {
      return true;
    }

    final l10n = context.shellL10n;
    final answer = await FerretConfirmDialog.show(
      context,
      title: l10n.localNetworkAskTitle,
      message: '${l10n.localNetworkAskBody}\n\n${l10n.localNetworkAskDetail}',
      negativeText: l10n.localNetworkAskNotNow,
      positiveText: l10n.localNetworkAskContinue,
    );
    if (answer != .positive) {
      return false;
    }

    await allow();
    return true;
  }

  bool _denied = false;

  /// Whether the person turned Local Network off for Ferret, as last
  /// checked by [refresh].
  bool get isDenied => _denied;

  /// Asks iOS whether Local Network is off for Ferret. Only once Ferret
  /// looks, since asking is looking.
  Future<bool> checkDenied() async {
    if (needsAsk) {
      return false;
    }

    return await _probe.check() == .denied;
  }

  /// Checks again, such as when the person comes back from Settings.
  Future<void> refresh() async {
    final denied = await checkDenied();
    if (denied == _denied) {
      return;
    }

    _denied = denied;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_devices?.cancel());
    super.dispose();
  }
}
