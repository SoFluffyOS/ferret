import 'dart:convert';
import 'dart:math';

import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:handoff/services/link_rules.dart';
import 'package:handoff/services/structured_data.dart';
import 'package:protocol/handoff.dart';

/// Builds activities from what the user shared, typed or had on screen.
abstract final class ActivityFactory {
  static final _link = RegExp(r'''(https?://[^\s<>"']+|geo:[^\s<>"']+)''');
  static final _edgePunctuation = RegExp(
    r'^[\s\p{P}]+|[\s\p{P}]+$',
    unicode: true,
  );
  static final _random = Random.secure();

  /// Longer text isn't a "continue" but a file; drop sends those.
  static const maxTextLength = 64 * 1024;
  static const maxStateBytes = 64 * 1024;

  static String newId() => [
    for (var index = 0; index < 16; index++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  /// A web or place activity when [text] holds a link, else a text one.
  static Activity? fromText(
    String text, {
    String title = '',
    String sourceAppName = '',
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxTextLength) {
      return null;
    }

    final link = _firstLink(trimmed);
    if (link == null) {
      return Activity(
        id: newId(),
        kind: .ACTIVITY_KIND_TEXT,
        title: _firstLine(title, trimmed),
        text: trimmed,
        sourceAppName: sourceAppName,
      );
    }

    final rest = trimmed
        .replaceFirst(link, ' ')
        .replaceAll(_edgePunctuation, '');
    final label = switch (title.trim()) {
      '' => rest,
      final explicit => explicit,
    };

    return Activity(
      id: newId(),
      kind: switch (LinkRules.isGeo(link)) {
        true => .ACTIVITY_KIND_GEO,
        false => .ACTIVITY_KIND_WEB,
      },
      title: _firstLine(label, _hostOf(link)),
      uri: link,
      sourceAppName: sourceAppName,
    );
  }

  /// What to copy for [activity]: its link, or its text when it has none.
  static String textOf(Activity activity) {
    for (final candidate in [
      activity.uri,
      activity.fallbackWebUri,
      activity.deepLink,
      activity.text,
    ]) {
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }

    return activity.title;
  }

  static Activity fromBrowserTab(BrowserTab tab) => Activity(
    id: newId(),
    kind: .ACTIVITY_KIND_WEB,
    title: _firstLine(tab.title, _hostOf(tab.url)),
    uri: tab.url,
    sourceAppName: tab.browserName,
  );

  static Activity? fromShared(SharedItem item) => switch (item.origin) {
    .shareSheet => fromText(
      item.text ?? '',
      title: item.subject ?? '',
      sourceAppName: item.appName ?? '',
    ),
    .assistant => fromAssist(item),
  };

  /// Maps what the Android assistant saw (AssistContent) to an activity.
  /// The app's own data wins over what the system guessed.
  static Activity? fromAssist(SharedItem item) {
    final data = StructuredData.parse(item.structuredData);
    final webUri = _firstOf([data.url, item.webUri ?? ''], LinkRules.isWeb);
    final deepLink = _firstOf([
      data.deepLink,
      item.deepLink ?? '',
    ], LinkRules.isAppLink);
    final fallback = _firstOf([
      data.fallbackUri,
      item.webUri ?? '',
      data.url,
    ], LinkRules.isWeb);
    final geo = data.geoUri;

    if (webUri.isEmpty && deepLink.isEmpty && geo.isEmpty) {
      return fromText(
        item.text ?? '',
        title: item.title ?? '',
        sourceAppName: item.appName ?? '',
      );
    }

    final kind = switch ((geo.isNotEmpty, deepLink.isNotEmpty)) {
      (true, _) => ActivityKind.ACTIVITY_KIND_GEO,
      (false, true) => ActivityKind.ACTIVITY_KIND_APP,
      (false, false) => ActivityKind.ACTIVITY_KIND_WEB,
    };
    final uri = switch (geo) {
      '' => webUri,
      _ => geo,
    };
    final state = _stateOf(data, item.structuredData);

    return Activity(
      id: newId(),
      kind: kind,
      title: _firstLine(
        _firstOf([data.name, item.title ?? ''], (value) => value.isNotEmpty),
        _hostOf(uri),
      ),
      uri: uri,
      deepLink: deepLink,
      fallbackWebUri: fallback,
      apps: AppIdentifiers(
        androidPackage: _firstOf([
          data.androidPackage,
          item.appPackage ?? '',
        ], (value) => value.isNotEmpty),
        appleBundleId: data.appleBundleId,
        linuxDesktopId: data.linuxDesktopId,
        windowsAppId: data.windowsAppId,
      ),
      state: state.bytes,
      stateType: state.type,
      sourceAppName: item.appName ?? '',
    );
  }

  static ({List<int> bytes, String type}) _stateOf(
    StructuredData data,
    String? rawJson,
  ) {
    if (data.state.isNotEmpty) {
      final bytes = utf8.encode(data.state);
      if (bytes.length <= maxStateBytes) {
        return (bytes: bytes, type: data.stateType);
      }
    }

    final json = rawJson?.trim() ?? '';
    final bytes = utf8.encode(json);
    if (json.isEmpty || bytes.length > maxStateBytes) {
      return (bytes: const [], type: '');
    }

    return (bytes: bytes, type: 'application/ld+json');
  }

  static String? _firstLink(String text) {
    final match = _link.firstMatch(text)?.group(0);
    if (match == null) {
      return null;
    }

    return match.replaceFirst(RegExp(r'[).,;:!?\]]+$'), '');
  }

  static String _firstOf(List<String> values, bool Function(String) accepts) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && accepts(trimmed)) {
        return trimmed;
      }
    }

    return '';
  }

  static String _firstLine(String preferred, String fallback) {
    final chosen = switch (preferred.trim()) {
      '' => fallback.trim(),
      final value => value,
    };
    final title = chosen.split('\n').first.trim();
    if (title.length <= 120) {
      return title;
    }

    return '${title.substring(0, 119)}…';
  }

  static String _hostOf(String uri) {
    final host = Uri.tryParse(uri)?.host ?? '';
    if (host.isEmpty) {
      return uri;
    }

    return host.replaceFirst(RegExp('^www\\.'), '');
  }
}
