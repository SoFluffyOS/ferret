import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where someone who likes Ferret can support its work. Ferret opens it
/// only when asked: never a popup, a banner or a reminder.
abstract final class Sponsor {
  static final page = Uri.parse('https://github.com/sponsors/simonpham');

  /// Whether this build offers [page]. The App Store counts a link to
  /// outside payments in an iPhone app against its rules (3.1.1), so the
  /// iPhone build leaves it out; every other build keeps it.
  static bool get isOffered => defaultTargetPlatform != .iOS;

  /// Opens [page] in the browser.
  static Future<bool> open() =>
      launchUrl(page, mode: LaunchMode.externalApplication);
}
