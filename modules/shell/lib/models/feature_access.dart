import 'package:protocol/protocol.dart';
import 'package:shell/l10n/l10n.dart';

/// Which features a paired device can be kept from, and what each one
/// carries between devices, in words.
abstract final class FeatureAccess {
  /// Features that never reach a paired device: Power-ups and the shelf
  /// stay on this device, and the iPhone link talks Bluetooth to an
  /// iPhone, not Ferret.
  static const localOnly = {'power', 'iphone', 'shelf'};

  /// Whether [featureId] does anything between a device on [here] and
  /// one on [there]: one of them offers it and the other can use it.
  /// What a device offers comes from what its platform's Ferret can do,
  /// not from what it said last, so the list doesn't change while it is
  /// offline. A platform Ferret doesn't know, or a feature it has no rule
  /// for, is always listed.
  static bool reaches(String featureId, Platform here, Platform there) {
    final (first, second) = (_kindOf(here), _kindOf(there));
    if (first == null || second == null) {
      return true;
    }

    final (offers, uses) = switch (featureId) {
      // An Android phone shares these; computers and an iPhone show them.
      'notifications' || 'messages' || 'calls' => (_android, _notAndroid),
      // A phone's screen or camera on a computer, and a Mac as another
      // Mac's extra display.
      'mirroring' => switch ((first, second)) {
        (.mac, .mac) => (_everyone, _everyone),
        _ => (_android, _computers),
      },
      // A phone as a touchpad, or a Mac's keyboard and mouse moving on to
      // another computer.
      'remote_input' => switch ((first, second)) {
        (.mac, .mac || .pc) || (.pc, .mac) => (_everyone, _everyone),
        _ => (_computers, _phones),
      },
      'actions' => (_computers, _everyone),
      // Every Ferret but the iPhone's shares what's playing.
      'media' => (_notIphone, _everyone),
      'camera' || 'photos' => (_phones, _computers),
      // A computer tells others how to wake it and sends the packet for
      // them. A phone wakes a computer with its own packet, so only
      // computers have something to keep from each other.
      'wake' => (_computers, _computers),
      _ => (_everyone, _everyone),
    };

    return (offers.contains(first) && uses.contains(second)) ||
        (offers.contains(second) && uses.contains(first));
  }

  /// Whether a phone offers to set up [featureId] in Do more. Notifications,
  /// texts and calls promise to show "on your computer", so they wait
  /// until a computer is among the [paired] devices.
  static bool offeredWith(String featureId, Iterable<Platform> paired) =>
      switch (featureId) {
        'notifications' || 'messages' || 'calls' => paired.any(
          (platform) => _computers.contains(_kindOf(platform)),
        ),
        _ => true,
      };

  static const _everyone = {
    _Kind.android,
    _Kind.iphone,
    _Kind.mac,
    _Kind.pc,
  };
  static const _android = {_Kind.android};
  static const _notAndroid = {_Kind.iphone, _Kind.mac, _Kind.pc};
  static const _notIphone = {_Kind.android, _Kind.mac, _Kind.pc};
  static const _phones = {_Kind.android, _Kind.iphone};
  static const _computers = {_Kind.mac, _Kind.pc};

  static _Kind? _kindOf(Platform platform) => switch (platform) {
    .PLATFORM_ANDROID => .android,
    .PLATFORM_IOS => .iphone,
    .PLATFORM_MACOS => .mac,
    .PLATFORM_WINDOWS || .PLATFORM_LINUX => .pc,
    _ => null,
  };

  static String? describe(ShellLocalizations l10n, String featureId) =>
      switch (featureId) {
        'clipboard' => l10n.accessClipboard,
        'drop' => l10n.accessDrop,
        'notifications' => l10n.accessNotifications,
        'messages' => l10n.accessMessages,
        'calls' => l10n.accessCalls,
        'handoff' => l10n.accessHandoff,
        'media' => l10n.accessMedia,
        'mirroring' => l10n.accessMirroring,
        'remote_input' => l10n.accessRemoteInput,
        'find' => l10n.accessFind,
        'actions' => l10n.accessActions,
        _ => null,
      };
}

enum _Kind { android, iphone, mac, pc }
