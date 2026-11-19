import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';

/// How likely a computer is to wake, from what it said about its cards.
enum WakeReadiness {
  /// A wired card with Wake-on-LAN on.
  ready,

  /// A wired card, but the computer couldn't tell whether it wakes.
  wiredUnknown,

  /// Its wired cards have Wake-on-LAN off.
  wiredOff,

  /// Only Wi-Fi: few computers wake over Wi-Fi.
  wifiOnly,

  /// It said nothing, such as an older Ferret or sharing turned off.
  unknown;

  static WakeReadiness of(WakeInfo? info) {
    final cards = [
      for (final card in info?.interfaces ?? const <WakeInterface>[])
        if (MacAddress.isUsable(card.mac)) card,
    ];
    final wired = cards.where((card) => card.link != .WAKE_LINK_WIFI);
    if (wired.any((card) => card.setting == .WAKE_SETTING_ON)) {
      return ready;
    }

    if (wired.any((card) => card.setting == .WAKE_SETTING_UNSPECIFIED)) {
      return wiredUnknown;
    }

    if (wired.isNotEmpty) {
      return wiredOff;
    }

    if (cards.isNotEmpty) {
      return wifiOnly;
    }

    return unknown;
  }
}
