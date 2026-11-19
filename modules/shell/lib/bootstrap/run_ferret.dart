import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_battery/ferret_battery.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shell/app/app.dart';
import 'package:shell/bootstrap/desktop_binding.dart';
import 'package:shell/bootstrap/menubar_binding.dart';
import 'package:shell/bootstrap/system_binding.dart';
import 'package:shell/l10n/l10n.dart';
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
  // Release builds print to the system log (logcat, Console.app), which
  // other tools can read; debug lines name devices and addresses.
  if (kReleaseMode) {
    Log.minimum = .info;
  }

  await initializeDateFormatting();

  final paths = await AppPaths.get();
  final settingsDirectory = await paths.create(paths.settings);
  final settings = await JsonFileSettingsStore.open(settingsDirectory.path);
  LanguagePreference.load(settings);
  final secrets = await createSecretStore(paths);
  final sharedComputer = SharedComputer(
    settings,
    environment: Platform.environment,
  );
  final described = await describeThisDevice(
    name: settings.get<String>(SharedComputer.nameKey),
    appVersion: appVersion,
  );
  final device = described.renamed(sharedComputer.nameFor(described.name));

  if (Platform.isAndroid) {
    await FerretSystem().acquireMulticastLock();
  }

  final engine = await FerretEngine.create(
    secrets: secrets,
    settings: settings,
    device: device,
    features: [for (final feature in features) feature.feature],
  );
  sharedComputer.follow(engine, computerName: described.name);
  await engine.start();

  final host = EngineHost(engine);
  final pause = PauseController(engine);
  final system = SystemBinding(engine: engine, host: host, pause: pause);
  await system.start();
  final screen = ScreenSession.forPlatform();
  await screen.start();
  await PresenceReporter(
    engine,
    isAtScreen: () => screen.isActive,
    atScreenChanges: screen.changes,
    battery: BatterySource.current(),
  ).start();
  final systemNotifier = await SystemNotifier.create([
    for (final feature in features) ...feature.noticeCategories,
  ]);
  final notifier = PrivateNotifier(
    systemNotifier,
    previews: PrivatePreviews(settings),
    isAtScreen: () => screen.isActive,
    coverBody: () => lookupShellLocalizations(
      AppLocale.pick(ShellLocalizations.supportedLocales),
    ).privateCoverBody,
  );
  unawaited(
    NotificationPermission(
      devices: engine.deviceChanges,
      hasDevices: () => engine.trustStore.devices.isNotEmpty,
      settings: settings,
      request: systemNotifier.requestPermission,
      asksHere: !Platform.isAndroid,
    ).start(),
  );
  LowBatteryNotices(
    devices: engine.deviceChanges,
    notifier: notifier,
    settings: settings,
    nameOf: engine.displayNameOf,
  ).start();
  final ferretMenubar = FerretMenubar();
  final views = AppViews(
    menubar: ferretMenubar,
    settings: settings,
    desktopWindow: switch (Platform.isWindows || Platform.isLinux) {
      true => DesktopWindow(),
      false => null,
    },
  );
  final featureContext = FeatureContext(
    engine: engine,
    navigatorKey: switch (ferretMenubar.isSupported) {
      true => views.navigatorKey,
      false => views.mainNavigatorKey,
    },
    notifier: notifier,
    onReveal: views.reveal,
    showsPreviewsFrom: (deviceId) =>
        screen.isActive && PrivatePreviews(settings).showsFrom(deviceId),
  );
  final featureWindows = FeatureWindowHost(menubar: ferretMenubar);
  featureContext.windows = featureWindows;
  final navigation = WindowNavRegistry(featureContext, views: views);
  for (final feature in features) {
    unawaited(feature.onAppStarted(featureContext));
  }

  await views.start();
  await featureWindows.start();
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
  await DesktopBinding(
    host: host,
    pause: pause,
    settings: settings,
    notifier: notifier,
  ).start();

  _run(
    FerretApp(
      host: host,
      pause: pause,
      features: features,
      featureContext: featureContext,
      menubar: menubar.menubar,
      navigation: navigation,
      featureWindows: featureWindows,
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
