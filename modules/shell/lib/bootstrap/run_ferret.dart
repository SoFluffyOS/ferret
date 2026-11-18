import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
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
  final pause = PauseController(engine);
  final system = SystemBinding(engine: engine, host: host, pause: pause);
  await system.start();
  await PresenceReporter(engine).start();

  final notifier = await SystemNotifier.create([
    for (final feature in features) ...feature.noticeCategories,
  ]);
  late final MenubarBinding menubar;
  final featureContext = FeatureContext(
    engine: engine,
    navigatorKey: GlobalKey<NavigatorState>(),
    notifier: notifier,
    onReveal: () => menubar.reveal(),
  );
  for (final feature in features) {
    unawaited(feature.onAppStarted(featureContext));
  }

  menubar = MenubarBinding(
    host: host,
    features: features,
    featureContext: featureContext,
  );
  await menubar.start();

  runApp(
    FerretApp(
      host: host,
      pause: pause,
      features: features,
      featureContext: featureContext,
    ),
  );
  onStarted?.call(engine);
}
