import 'dart:async';

import 'package:core/core.dart';

/// Notices that Ferret was updated since it last ran, so Home can say so
/// once, in one quiet line, with a link to what changed.
class WhatsNew {
  const WhatsNew(this._settings);

  /// The Ferret version that last ran here.
  static const seenVersionKey = 'shell.seen_version';

  final SettingsStore _settings;

  /// The version Ferret was updated to, the first time it runs after an
  /// update, else null. A fresh install has nothing new to tell: it has no
  /// version stored and nothing paired yet. Installs from before this was
  /// stored count as updated once they have paired devices.
  String? takeUpdate({required String appVersion, required bool hasPaired}) {
    if (appVersion.isEmpty) {
      return null;
    }

    final seen = _settings.get<String>(seenVersionKey);
    if (seen == appVersion) {
      return null;
    }

    unawaited(_settings.set(seenVersionKey, appVersion));
    if (seen == null && !hasPaired) {
      return null;
    }

    return appVersion;
  }

  /// Where every Ferret release is published.
  static final releases = Uri.parse(
    'https://github.com/SoFluffyOS/ferret/releases',
  );

  /// Where the release notes of [version] are.
  static Uri notesFor(String version) => Uri.parse(
    'https://github.com/SoFluffyOS/ferret/releases/tag/v$version',
  );
}
