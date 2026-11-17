import 'dart:io';

import 'package:ferret_system/src/messages.g.dart';

/// System hooks for Ferret. Calls are no-ops where a platform doesn't need
/// them.
class FerretSystem {
  FerretSystem({SystemHostApi? api}) : _api = api ?? SystemHostApi();

  final SystemHostApi _api;

  /// Android drops multicast packets unless an app holds this lock, which
  /// discovery needs. Release it when Ferret stops listening.
  Future<void> acquireMulticastLock() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _api.acquireMulticastLock();
  }

  Future<void> releaseMulticastLock() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _api.releaseMulticastLock();
  }
}
