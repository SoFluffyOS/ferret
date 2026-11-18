import 'package:handoff/models/models.dart';
import 'package:handoff/services/activity_opener.dart';
import 'package:handoff/services/browser/browser_tab_opener.dart';
import 'package:protocol/handoff.dart';

/// Opens web pages in the browser the user is looking at, through its
/// extension, and everything else (or when no browser is in front) with
/// [fallback].
class BrowserFirstOpener implements ActivityOpener {
  BrowserFirstOpener({required this.fallback, this.browser});

  final ActivityOpener fallback;

  /// Set once the bridge exists, which needs the feature this opener is
  /// given to. Until then everything goes to [fallback].
  BrowserTabOpener? browser;

  @override
  Future<OpenResult> open(Activity activity) async {
    if (await browser?.openInBrowser(activity) ?? false) {
      return .opened;
    }

    return fallback.open(activity);
  }
}
