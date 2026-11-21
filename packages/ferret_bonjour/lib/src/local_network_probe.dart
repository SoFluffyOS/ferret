import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What iOS lets Ferret do on the local network, as far as it can tell.
enum LocalNetworkState {
  /// The Local Network switch for Ferret is off.
  denied,

  /// Ferret may look for devices.
  allowed,

  /// Nothing to tell, such as on another platform or before iOS asked.
  unknown,
}

/// Asks the iPhone whether Ferret is allowed on the local network. Browsing
/// is what makes iOS ask, so only check once Ferret explained why and let
/// discovery start. Elsewhere it is always [LocalNetworkState.unknown].
class LocalNetworkProbe {
  const LocalNetworkProbe({bool? isIos}) : _isIos = isIos;

  static const _channel = MethodChannel(
    'io.sofluffy.ferret_bonjour/local_network',
  );

  final bool? _isIos;

  Future<LocalNetworkState> check() async {
    if (!(_isIos ?? defaultTargetPlatform == .iOS)) {
      return .unknown;
    }

    try {
      return switch (await _channel.invokeMethod<String>('check')) {
        'denied' => .denied,
        'allowed' => .allowed,
        _ => .unknown,
      };
    } on Object {
      return .unknown;
    }
  }
}
