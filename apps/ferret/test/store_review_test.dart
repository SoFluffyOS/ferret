// What App Review and Google Play check before they read a line of the
// app: the iOS privacy manifests, the permission prompts, background modes
// and the Play build's permissions.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _repo = Directory('../..');
final _runner = '${_repo.path}/apps/ferret/ios/Runner';

/// Swift that calls a required-reason API, by the manifest category it
/// needs. https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
final _requiredReasonApis = {
  'NSPrivacyAccessedAPICategoryUserDefaults': RegExp(r'\bUserDefaults\b'),
  'NSPrivacyAccessedAPICategoryDiskSpace': RegExp(
    r'volumeAvailableCapacity|volumeTotalCapacity|systemFreeSize|systemSize\b|\bstatv?fs\(',
  ),
  'NSPrivacyAccessedAPICategoryFileTimestamp': RegExp(
    r'attributesOfItem|setAttributes|ModificationDateKey|creationDateKey|contentAccessDateKey|\bf?stat\(|getattrlist',
  ),
  'NSPrivacyAccessedAPICategorySystemBootTime': RegExp(
    r'systemUptime|mach_absolute_time',
  ),
  'NSPrivacyAccessedAPICategoryActiveKeyboards': RegExp(r'activeInputModes'),
};

/// Background modes the iPhone build may declare. Ferret syncs only while
/// it is open, and App Review rejects a mode the app doesn't use (2.5.4).
const _allowedBackgroundModes = <String>{};

/// Permissions the Google Play build must not ask for.
const _notOnPlay = {
  // Only Play may update an app installed from Play.
  'android.permission.REQUEST_INSTALL_PACKAGES',
};

Set<String> _declaredCategories(File manifest) => {
  for (final match in RegExp(
    r'<string>(NSPrivacyAccessedAPICategory\w+)</string>',
  ).allMatches(manifest.readAsStringSync()))
    match.group(1)!,
};

Set<String> _categoriesUsedIn(Iterable<File> swift) => {
  for (final file in swift)
    for (final MapEntry(key: category, value: pattern)
        in _requiredReasonApis.entries)
      if (pattern.hasMatch(file.readAsStringSync())) category,
};

List<File> _swiftIn(Directory directory) => [
  for (final entity in directory.listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.swift')) entity,
];

/// The iOS source folders of Ferret's own plugins.
List<Directory> _pluginSources() => [
  for (final package in Directory('${_repo.path}/packages').listSync())
    if (package is Directory)
      if (Directory('${package.path}/ios/${_name(package)}/Sources')
          case final sources when sources.existsSync())
        sources.parent,
];

String _name(Directory directory) =>
    directory.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);

/// A plugin's or the app's own AndroidManifest.xml, not a build output's
/// or an example's. Windows lists paths with `\`, so they're read with `/`.
bool _isMainManifest(String path) {
  final posix = path.replaceAll(r'\', '/');
  return posix.endsWith('AndroidManifest.xml') &&
      posix.contains('/src/main/') &&
      !posix.contains('/build/') &&
      !posix.contains('/example/');
}

Map<String, String> _plistStrings(String plist) => {
  for (final match in RegExp(
    r'<key>(\w+)</key>\s*<string>([^<]*)</string>',
  ).allMatches(plist))
    match.group(1)!: match.group(2)!,
};

void main() {
  group('iOS privacy manifests', () {
    test('every plugin declares the required-reason APIs it calls', () {
      final missing = <String>[];
      for (final plugin in _pluginSources()) {
        final used = _categoriesUsedIn(_swiftIn(plugin));
        if (used.isEmpty) {
          continue;
        }

        final manifests = [
          for (final entity in plugin.listSync(recursive: true))
            if (entity is File && entity.path.endsWith('PrivacyInfo.xcprivacy'))
              entity,
        ];
        final declared = {
          for (final manifest in manifests) ..._declaredCategories(manifest),
        };
        for (final category in used.difference(declared)) {
          missing.add('${plugin.path}: $category');
        }

        final package = File('${plugin.path}/Package.swift');
        if (!package.readAsStringSync().contains(
          RegExp(r'^\s*\.process\("PrivacyInfo\.xcprivacy"\)', multiLine: true),
        )) {
          missing.add('${package.path}: manifest not bundled');
        }
      }

      expect(missing, isEmpty);
    });

    test('the app declares every category its plugins and Runner use', () {
      final used = {
        ..._categoriesUsedIn(_swiftIn(Directory(_runner))),
        for (final plugin in _pluginSources())
          ..._categoriesUsedIn(_swiftIn(plugin)),
      };
      final declared = _declaredCategories(
        File('$_runner/PrivacyInfo.xcprivacy'),
      );

      expect(used.difference(declared), isEmpty);
    });

    test('Ferret tracks no one and collects nothing', () {
      final manifest = File(
        '$_runner/PrivacyInfo.xcprivacy',
      ).readAsStringSync();

      expect(
        manifest,
        matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')),
      );
      expect(
        manifest,
        matches(RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>')),
      );
    });
  });

  group('iOS Info.plist', () {
    final plist = File('$_runner/Info.plist').readAsStringSync();

    test('every permission prompt is in English and Vietnamese', () {
      final catalog = jsonDecode(
        File('$_runner/InfoPlist.xcstrings').readAsStringSync(),
      ) as Map<String, dynamic>;
      final strings = catalog['strings'] as Map<String, dynamic>;
      final prompts = {
        for (final MapEntry(:key, :value) in _plistStrings(plist).entries)
          if (key.endsWith('UsageDescription')) key: value,
      };

      expect(prompts, isNotEmpty);
      for (final MapEntry(:key, :value) in prompts.entries) {
        final localizations =
            (strings[key] as Map<String, dynamic>?)?['localizations']
                as Map<String, dynamic>?;
        String? text(String language) =>
            ((localizations?[language] as Map<String, dynamic>?)?['stringUnit']
                    as Map<String, dynamic>?)?['value']
                as String?;

        expect(text('en'), value, reason: '$key: English matches Info.plist');
        expect(text('vi'), isNotEmpty, reason: '$key: Vietnamese');
      }
    });

    test('declares only background modes Ferret uses', () {
      final modes = RegExp(
        r'<key>UIBackgroundModes</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)?.group(1);
      final declared = {
        for (final match in RegExp(
          '<string>([^<]*)</string>',
        ).allMatches(modes ?? ''))
          match.group(1)!,
      };

      expect(declared.difference(_allowedBackgroundModes), isEmpty);
    });

    test('lists the Bonjour service it browses', () {
      expect(plist, contains('<string>_ferret._tcp</string>'));
    });
  });

  group('Google Play build', () {
    final android = '${_repo.path}/apps/ferret/android/app';

    test('leaves out the permissions Play forbids', () {
      final play = File('$android/src/play/AndroidManifest.xml');
      final gradle = File('$android/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('"FERRET_STORE=play"'));
      expect(gradle, contains('src/play/AndroidManifest.xml'));
      for (final permission in _notOnPlay) {
        expect(
          play.readAsStringSync(),
          matches(
            RegExp(
              'android:name="${RegExp.escape(permission)}"\\s*'
              'tools:node="remove"',
            ),
          ),
          reason: permission,
        );
      }
    });

    test('asks for no permission Play holds back for special apps', () {
      final manifests = [
        for (final root in ['packages', 'modules', 'apps/ferret/android'])
          for (final entity in Directory(
            '${_repo.path}/$root',
          ).listSync(recursive: true))
            if (entity is File && _isMainManifest(entity.path)) entity,
      ];
      const refused = [
        'android.permission.QUERY_ALL_PACKAGES',
        'android.permission.MANAGE_EXTERNAL_STORAGE',
        'android.permission.ACCESS_BACKGROUND_LOCATION',
        'android.permission.READ_PHONE_NUMBERS',
      ];

      expect(manifests, isNotEmpty);
      for (final manifest in manifests) {
        final text = manifest.readAsStringSync();
        for (final permission in refused) {
          expect(text, isNot(contains(permission)), reason: manifest.path);
        }
      }
    });
  });
}
