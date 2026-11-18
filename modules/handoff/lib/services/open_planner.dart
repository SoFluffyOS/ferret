import 'package:handoff/models/models.dart';
import 'package:handoff/services/geo_link.dart';
import 'package:handoff/services/link_rules.dart';
import 'package:protocol/handoff.dart';
import 'package:protocol/protocol.dart';

/// Decides how this device opens an activity: the app's deep link when the
/// app is here, else the fallback web page.
abstract final class OpenPlanner {
  static List<OpenStep> plan(Activity activity, Platform platform) {
    if (activity.kind == .ACTIVITY_KIND_TEXT) {
      return switch (activity.text.trim()) {
        '' => const [],
        _ => [CopyText(activity.text)],
      };
    }

    final appId = appIdFor(activity.apps, platform);
    final deepLink = activity.deepLink.trim();
    final uri = activity.uri.trim();
    final fallback = activity.fallbackWebUri.trim();
    final steps = <OpenStep>[];

    if (LinkRules.isAppLink(deepLink)) {
      if (appId.isNotEmpty) {
        steps.add(OpenInApp(deepLink, appId));
      }

      steps.add(OpenLink(deepLink, appsOnly: true));
    }

    if (appId.isNotEmpty && LinkRules.isWeb(uri)) {
      steps.add(OpenInApp(uri, appId));
    }

    if (LinkRules.isGeo(uri)) {
      steps.addAll(_geoSteps(uri, platform));
    }

    for (final link in [uri, fallback]) {
      if (LinkRules.isPlain(link) && !LinkRules.isGeo(link)) {
        steps.add(OpenLink(link));
      }
    }

    return _withoutRepeats(steps);
  }

  /// The id of the app that continues an activity on [platform], or empty.
  static String appIdFor(AppIdentifiers apps, Platform platform) =>
      switch (platform) {
        .PLATFORM_ANDROID => apps.androidPackage,
        .PLATFORM_MACOS || .PLATFORM_IOS => apps.appleBundleId,
        .PLATFORM_LINUX => apps.linuxDesktopId,
        .PLATFORM_WINDOWS => apps.windowsAppId,
        _ => '',
      }.trim();

  static List<OpenStep> _geoSteps(String uri, Platform platform) {
    final place = GeoLink.parse(uri);
    if (place == null) {
      return const [];
    }

    return switch (platform) {
      .PLATFORM_MACOS || .PLATFORM_IOS => [OpenLink(place.appleMapsUrl)],
      .PLATFORM_ANDROID => [OpenLink(uri), OpenLink(place.openStreetMapUrl)],
      _ => [OpenLink(uri, appsOnly: true), OpenLink(place.openStreetMapUrl)],
    };
  }

  static List<OpenStep> _withoutRepeats(List<OpenStep> steps) {
    final seen = <OpenStep>{};
    return [
      for (final step in steps)
        if (seen.add(step)) step,
    ];
  }
}
