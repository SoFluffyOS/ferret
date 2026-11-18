import 'dart:convert';

import 'package:handoff/services/activity_factory.dart';
import 'package:handoff/services/link_rules.dart';
import 'package:protocol/handoff.dart';

/// A browser tab as the extension describes it, and the position (video
/// time, scroll) that travels with it in the activity's `state`.
class ExtensionTab {
  const ExtensionTab({
    required this.url,
    required this.title,
    this.videoTime,
    this.scrollY,
  });

  static const stateType = 'application/vnd.ferret.page-position+json';
  static const maxUrlLength = 8 * 1024;
  static const _maxTitleLength = 300;

  final String url;
  final String title;

  /// Seconds into the page's main video.
  final double? videoTime;

  /// Pixels scrolled from the top.
  final int? scrollY;

  /// Reads the extension's `tab` object. Null unless it holds an http(s)
  /// link of a sane length.
  static ExtensionTab? fromJson(Object? json) {
    if (json case {'url': final String url}) {
      final trimmed = url.trim();
      if (trimmed.length > maxUrlLength || !LinkRules.isWeb(trimmed)) {
        return null;
      }

      final title = switch (json) {
        {'title': final String title} => title,
        _ => '',
      };
      return ExtensionTab(
        url: trimmed,
        title: _clip(title),
        videoTime: _videoTimeOf(json['videoTime']),
        scrollY: _scrollOf(json['scrollY']),
      );
    }

    return null;
  }

  /// The position saved in [activity], when it came from a browser.
  static ({double? videoTime, int? scrollY}) positionOf(Activity activity) {
    if (activity.stateType != stateType || activity.state.isEmpty) {
      return (videoTime: null, scrollY: null);
    }

    try {
      final decoded = jsonDecode(utf8.decode(activity.state));
      if (decoded case final Map<String, Object?> position) {
        return (
          videoTime: _videoTimeOf(position['video_time']),
          scrollY: _scrollOf(position['scroll_y']),
        );
      }
    } on FormatException {
      return (videoTime: null, scrollY: null);
    }

    return (videoTime: null, scrollY: null);
  }

  Activity toActivity({required String browser}) {
    final result = Activity(
      id: ActivityFactory.newId(),
      kind: .ACTIVITY_KIND_WEB,
      title: switch (title) {
        '' => _hostOf(url),
        _ => title,
      },
      uri: url,
      sourceAppName: browser,
    );

    final position = {
      'video_time': ?videoTime,
      'scroll_y': ?scrollY,
    };
    if (position.isEmpty) {
      return result;
    }

    return result
      ..state = utf8.encode(jsonEncode(position))
      ..stateType = stateType;
  }

  static double? _videoTimeOf(Object? value) {
    if (value case final num seconds when seconds.isFinite && seconds >= 0) {
      return seconds.toDouble();
    }

    return null;
  }

  static int? _scrollOf(Object? value) {
    if (value case final num pixels when pixels.isFinite && pixels >= 0) {
      return pixels.round();
    }

    return null;
  }

  static String _hostOf(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.isEmpty) {
      return url;
    }

    return host.replaceFirst(RegExp('^www\\.'), '');
  }

  static String _clip(String title) {
    final line = title.split('\n').first.trim();
    if (line.length <= _maxTitleLength) {
      return line;
    }

    return line.substring(0, _maxTitleLength);
  }
}
