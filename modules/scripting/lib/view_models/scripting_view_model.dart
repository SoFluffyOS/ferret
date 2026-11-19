import 'package:flutter/foundation.dart';
import 'package:scripting/services/services.dart';

/// What Settings shows about scripts on a computer: the hooks folder and
/// which hooks would run.
class ScriptingViewModel extends ChangeNotifier {
  ScriptingViewModel(this.hooks);

  final HookRunner? hooks;

  List<String> _installed = const [];
  bool _disposed = false;

  String get folder => hooks?.directory ?? '';

  /// Event types that have a hook ready to run.
  List<String> get installed => _installed;

  Future<void> refresh() async {
    final runner = hooks;
    if (runner == null) {
      return;
    }

    final found = await runner.installed();
    if (_disposed || listEquals(found, _installed)) {
      return;
    }

    _installed = found;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
