import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';

/// Android 17's local network permission, asked in context: Ferret says
/// why first, then Android asks. Turned down for good, the way back is
/// Ferret's page in Android's settings. Re-checked whenever the user comes
/// back from there.
class LocalNetworkViewModel extends ChangeNotifier {
  LocalNetworkViewModel({FerretSystem? system})
    : _system = system ?? FerretSystem();

  final FerretSystem _system;
  bool _disposed = false;

  LocalNetworkAccess access = .notNeeded;

  /// Whether Ferret still needs the user's OK to reach this network.
  bool get asks => access == .notGranted || access == .blocked;

  /// Whether Android won't show its question again.
  bool get isBlocked => access == .blocked;

  Future<void> refresh() async {
    final before = access;
    access = await _system.localNetworkAccess();
    _wake(before);
    _notify();
  }

  /// Shows Android's question, or Ferret's page in Settings when Android
  /// won't ask any more.
  Future<void> allow() async {
    final before = access;
    if (before == .blocked) {
      await _system.openAppSettings();
      return;
    }

    access = await _system.requestLocalNetworkAccess();
    _wake(before);
    _notify();
  }

  /// Allowed just now: look for devices again straight away rather than at
  /// the next retry, the way joining a network does.
  void _wake(LocalNetworkAccess before) {
    if (access != .granted || before == .granted || before == .notNeeded) {
      return;
    }

    _system.onNetworkChange(.available);
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
