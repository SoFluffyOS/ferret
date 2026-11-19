import 'package:url_launcher/url_launcher.dart';

/// Where someone who likes Ferret can support its work. Ferret opens it
/// only when asked: never a popup, a banner or a reminder.
abstract final class Sponsor {
  static final page = Uri.parse('https://github.com/sponsors/simonpham');

  /// Opens [page] in the browser.
  static Future<bool> open() =>
      launchUrl(page, mode: LaunchMode.externalApplication);
}
