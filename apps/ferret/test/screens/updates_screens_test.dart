// Updates: the Needs you line when a newer Ferret is ready, What's new, the
// download, a refused download, Android's permission ask, and the switch in
// About. Renders into temp/screens as `updates_<name>_<size>_<mode>.png`.
// Run one at a time from apps/ferret:
//
//   fvm flutter test test/screens/updates_screens_test.dart --plain-name "updates card popover light"
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';
import 'package:updates/updates.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

const _window = CaptureSize('window', 1000, 720);
const _payload = 'Ferret 0.2.0';

const _notes = '''
## What's new
- **Updates**: Ferret tells you when a new version is out, and installs it when you say so.
- Files arrive straight in Downloads on Android.

## Fixed
- Reconnects faster after the Wi-Fi drops.
''';

final _release = UpdateRelease(
  tag: 'v0.2.0',
  notes: _notes,
  assets: [
    for (final name in [
      'Ferret-mac.dmg',
      'Ferret-android.apk',
      UpdateTarget.checksumsName,
    ])
      UpdateAsset(
        name: name,
        downloadUrl: Uri.https('github.com', '/SoFluffyOS/ferret/$name'),
        size: 1000,
      ),
  ],
);

class _OneRelease implements ReleaseSource {
  @override
  Future<UpdateRelease?> newest({required bool includePreReleases}) async =>
      _release;
}

/// Never touches the network: lists the right checksum and, when told,
/// stops a download at 42%.
class _QuietHttp extends UpdateHttp {
  _QuietHttp({this.hang = false});

  final bool hang;

  @override
  Future<String?> getText(Uri url, {String? accept, int maxBytes = 0}) async {
    final hash = sha256.convert(utf8.encode(_payload));
    return '$hash  Ferret-mac.dmg\n$hash  Ferret-android.apk\n';
  }

  @override
  Future<void> download(
    Uri url,
    File destination, {
    int expectedSize = 0,
    void Function(double? progress)? onProgress,
    Future<void>? cancelled,
  }) async {
    onProgress?.call(0.42);
    if (hang) {
      await cancelled;
      throw const UpdateDownloadCancelled();
    }

    await destination.writeAsString(_payload);
  }
}

class _Installer implements UpdateInstaller {
  _Installer({this.refuse, this.outcome = .quitToRestart});

  final RefusalReason? refuse;
  final InstallOutcome outcome;

  @override
  Future<InstallOutcome> install(File file) async {
    if (refuse case final reason?) {
      throw UpdateRefused(reason);
    }

    return outcome;
  }
}

typedef _Make = UpdatesViewModel Function(bool asPhone);

UpdatesViewModel _viewModel({
  required bool asPhone,
  InstallKind? kind,
  UpdateHttp? http,
  UpdateInstaller? installer,
  SettingsStore? settings,
}) {
  final store = settings ?? MemorySettingsStore();
  return UpdatesViewModel(
    platform: UpdatePlatform(
      kind:
          kind ??
          switch (asPhone) {
            true => .androidApk,
            false => .macApp,
          },
      target: switch (asPhone) {
        true => .android,
        false => .mac,
      },
      source: _OneRelease(),
      http: http ?? _QuietHttp(),
      installer: installer ?? _Installer(),
    ),
    currentVersion: '0.1.0',
    settings: () => UpdateSettings(store),
    quit: () async {},
    downloads: () => Directory.systemTemp.createTemp('updates_render'),
  );
}

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  UpdatesViewModel viewModel,
);

Future<void> _check(
  WidgetTester tester,
  ScreenRig rig,
  UpdatesViewModel viewModel,
) async {
  await tester.runAsync(viewModel.check);
  await rig.settle(tester);
}

Future<void> _install(
  WidgetTester tester,
  ScreenRig rig,
  UpdatesViewModel viewModel,
) async {
  await _check(tester, rig, viewModel);
  await tester.runAsync(() async {
    unawaited(viewModel.install());
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await rig.settle(tester);
}

final _screens = <String, ({_Make make, _Script script, bool phoneOnly})>{
  'card': (
    make: (asPhone) => _viewModel(asPhone: asPhone),
    script: _check,
    phoneOnly: false,
  ),
  'whats_new': (
    make: (asPhone) => _viewModel(asPhone: asPhone),
    script: (tester, rig, viewModel) async {
      await _check(tester, rig, viewModel);
      await tester.tap(find.text("What's new").first);
      await rig.settle(tester);
    },
    phoneOnly: false,
  ),
  'downloading': (
    make: (asPhone) =>
        _viewModel(asPhone: asPhone, http: _QuietHttp(hang: true)),
    script: _install,
    phoneOnly: false,
  ),
  'refused': (
    make: (asPhone) => _viewModel(
      asPhone: asPhone,
      installer: _Installer(refuse: .wrongPublisher),
    ),
    script: _install,
    phoneOnly: false,
  ),
  'package_manager': (
    make: (asPhone) => _viewModel(asPhone: asPhone, kind: .packageManager),
    script: _check,
    phoneOnly: false,
  ),
  'permission': (
    make: (asPhone) => _viewModel(
      asPhone: asPhone,
      installer: _Installer(outcome: .needsPermission),
    ),
    script: _install,
    phoneOnly: true,
  ),
  'about': (
    make: (asPhone) => _viewModel(asPhone: asPhone),
    script: (tester, rig, viewModel) async {
      await _check(tester, rig, viewModel);
      await rig.open(tester, const AboutPage());
    },
    phoneOnly: false,
  ),
  'about_up_to_date': (
    make: (asPhone) => _viewModel(asPhone: asPhone),
    script: (tester, rig, viewModel) async {
      await rig.open(tester, const AboutPage());
    },
    phoneOnly: false,
  ),
};

void main() {
  setUpAll(loadScreenFonts);

  for (final MapEntry(key: name, value: screen) in _screens.entries) {
    for (final size in [popover, _window, phone]) {
      final asPhone = size == phone;
      if (screen.phoneOnly && !asPhone) {
        continue;
      }

      for (final brightness in Brightness.values) {
        testWidgets('updates $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = switch (asPhone) {
            true => TargetPlatform.android,
            false => TargetPlatform.macOS,
          };
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              return;
            }
            reportError?.call(details);
          };
          try {
            final viewModel = screen.make(asPhone);
            final updates = UpdatesFeatureUi(viewModel: viewModel);
            final features = <FeatureUi>[
              ...switch (asPhone) {
                true => phoneFeatures(),
                false => appFeatures(),
              },
              updates,
            ];
            final rig = await ScreenRig.create(
              tester,
              features: features,
              tipsDone: true,
              asPhone: asPhone,
            );
            await rig.show(tester);
            if (asPhone) {
              await rig.pairConnectedComputer(
                tester,
                computerFeatures: appFeatures(),
              );
            }
            if (!asPhone) {
              await rig.pairConnectedPhone(
                tester,
                phoneFeatures: phoneFeatures(),
                name: 'Pixel 7',
              );
            }
            await screen.script(tester, rig, viewModel);
            await rig.capture(tester, 'updates_$name', size, brightness);
            viewModel.cancel();
            await rig.dispose(tester);
          } finally {
            FlutterError.onError = reportError;
            debugDisableShadows = true;
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}
