import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/bootstrap/menubar_binding.dart';
import 'package:shell/services/services.dart';

/// Starts Ferret with [features]: storage, the engine, platform hooks, and
/// the app.
Future<void> runFerret({
  required List<FeatureUi> features,
  String appVersion = '',
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDirectory = await getApplicationSupportDirectory();
  final settings = await JsonFileSettingsStore.open(supportDirectory.path);
  final secrets = await createSecretStore();
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
  final notifier = await SystemNotifier.create([
    for (final feature in features) ...feature.noticeCategories,
  ]);
  final featureContext = FeatureContext(
    engine: engine,
    navigatorKey: GlobalKey<NavigatorState>(),
    notifier: notifier,
  );
  for (final feature in features) {
    unawaited(feature.onAppStarted(featureContext));
  }

  final menubar = MenubarBinding(
    host: host,
    features: features,
    featureContext: featureContext,
  );
  await menubar.start();

  runApp(
    FerretApp(host: host, features: features, featureContext: featureContext),
  );
}
