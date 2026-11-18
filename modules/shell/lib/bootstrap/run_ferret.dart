import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shell/app/app.dart';
import 'package:shell/bootstrap/menubar_binding.dart';
import 'package:shell/bootstrap/system_binding.dart';
import 'package:shell/services/services.dart';

/// Starts Ferret with [features]: storage, the engine, platform hooks, and
/// the app. [onStarted] gets the running engine, for wiring between
/// features that the app owns.
Future<void> runFerret({
  required List<FeatureUi> features,
  String appVersion = '',
  void Function(FerretEngine engine)? onStarted,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final paths = await AppPaths.get();
  final settingsDirectory = await paths.create(paths.settings);
  final settings = await JsonFileSettingsStore.open(settingsDirectory.path);
  final secrets = await createSecretStore(paths);
  final device = await describeThisDevice(
    name: settings.get<String>('device.name'),
    appVersion: appVersion,
  );

  if (Platform.isAndroid) {
    await FerretSystem().acquireMulticastLock();
  }

  final engine = await FerretEngine.create(
    secrets: secrets,
    settings: settings,
    device: device,
    features: [for (final feature in features) feature.feature],
  );
  await engine.start();

  final host = EngineHost(engine);
  final pause = PauseController(engine);
  final system = SystemBinding(engine: engine, host: host, pause: pause);
  await system.start();
  await PresenceReporter(engine).start();

  final notifier = await SystemNotifier.create([
    for (final feature in features) ...feature.noticeCategories,
  ]);
  final ferretMenubar = FerretMenubar();
  final views = AppViews(menubar: ferretMenubar, settings: settings);
  final featureContext = FeatureContext(
    engine: engine,
    navigatorKey: switch (ferretMenubar.isSupported) {
      true => views.navigatorKey,
      false => views.mainNavigatorKey,
    },
    notifier: notifier,
    onReveal: views.reveal,
  );
  final navigation = WindowNavRegistry(featureContext, views: views);
  for (final feature in features) {
    unawaited(feature.onAppStarted(featureContext));
  }

  await views.start();
  final menubar = MenubarBinding(
    host: host,
    pause: pause,
    features: features,
    featureContext: featureContext,
    views: views,
    navigation: navigation,
    menubar: ferretMenubar,
  );
  await menubar.start();

  _run(
    FerretApp(
      host: host,
      pause: pause,
      features: features,
      featureContext: featureContext,
      menubar: menubar.menubar,
      navigation: navigation,
      views: switch (ferretMenubar.isSupported) {
        true => views,
        false => null,
      },
    ),
  );
  onStarted?.call(engine);
}

/// With several views the app places each one itself; with one, Flutter
/// puts the app in it.
void _run(FerretApp app) {
  if (app.views == null) {
    runApp(app);
    return;
  }

  runWidget(app);
}
