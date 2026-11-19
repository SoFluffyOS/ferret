import 'package:shell/l10n/l10n.dart';

/// Which features a paired device can be kept from, and what each one
/// carries between devices, in words.
abstract final class FeatureAccess {
  /// Features that never reach a paired device: Power-ups stays on this
  /// device, and the iPhone link talks Bluetooth to an iPhone, not Ferret.
  static const localOnly = {'power', 'iphone'};

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
