import 'package:protocol/handoff.dart';

/// Opens a web activity in a browser that has the Ferret extension.
abstract interface class BrowserTabOpener {
  /// True once a browser in front opened it in a new tab; false when no
  /// browser is in front or it didn't answer in time.
  Future<bool> openInBrowser(Activity activity);
}
