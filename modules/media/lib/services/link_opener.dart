import 'package:core/core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens links in the right app on this device.
abstract interface class LinkOpener {
  /// Returns false when no app here could open [uri].
  Future<bool> open(Uri uri);
}

/// Opens links with `url_launcher`, in the app that handles them.
class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: .externalApplication);
    } on Object catch (error) {
      printDebug('No app opened a ${uri.scheme} link (${error.runtimeType})');
      return false;
    }
  }
}
