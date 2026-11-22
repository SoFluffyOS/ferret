import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_battery/ferret_battery.dart';
import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shell/app/app.dart';
import 'package:shell/bootstrap/boot_host.dart';
import 'package:shell/bootstrap/desktop_binding.dart';
import 'package:shell/bootstrap/launch_messages.dart';
import 'package:shell/bootstrap/menubar_binding.dart';
import 'package:shell/bootstrap/menubar_boot.dart';
import 'package:shell/bootstrap/splash_look.dart';
import 'package:shell/bootstrap/system_binding.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/pages.dart';
import 'package:transport/transport.dart';

/// Starts Ferret with [features]: storage, the engine, platform hooks, and
/// the app. [onStarted] gets the running engine, for wiring between
/// features that the app owns. [multicastNeed] is shared with features
/// that listen to the network themselves, such as Drop's LocalSend.
///
/// A phone or a Windows or Linux window draws its first frame right away,
/// carrying on the launch screen, and the app fades in once it is ready.
/// The Mac's popover shows nothing until the whole app is there.
Future<void> runFerret({
  required List<FeatureUi> features,
  String appVersion = '',
  void Function(FerretEngine engine)? onStarted,
  MulticastNeed? multicastNeed,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Release builds print to the system log (logcat, Console.app), which
  // other tools can read; debug lines name devices and addresses, and an
  // error's text can hold a path or a link.
  if (kReleaseMode) {
    Log.minimum = .info;
    Log.redactErrors = true;
    // Uncaught errors would otherwise reach the system log whole.
    FlutterError.onError = (details) =>
        printError('Uncaught Flutter error', details.exception, details.stack);
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      printError('Uncaught error', error, stackTrace);
      return true;
    };
  }
  LaunchMessages.hold();

  Future<FerretApp> start() => _start(
    features: features,
    appVersion: appVersion,
    onStarted: onStarted,
    multicastNeed: multicastNeed,
  );

  if (Platform.isMacOS) {
    await MenubarBoot.run(start);
    return;
  }

  runApp(BootHost(start: start, look: SplashLook.current));
}

/// Everything Ferret needs before its app can show. When a step fails,
/// the engine it may have started stops again, so Try again starts clean.
Future<FerretApp> _start({
  required List<FeatureUi> features,
  required String appVersion,
  required void Function(FerretEngine engine)? onStarted,
  required MulticastNeed? multicastNeed,
}) async {
  FerretEngine? started;
  try {
    return await _startApp(
      features: features,
      appVersion: appVersion,
      onStarted: onStarted,
      multicastNeed: multicastNeed,
      onEngine: (engine) => started = engine,
    );
  } on Object {
    await started?.shutdown();
    rethrow;
  }
}

Future<FerretApp> _startApp({
  required List<FeatureUi> features,
  required String appVersion,
  required void Function(FerretEngine engine)? onStarted,
  required MulticastNeed? multicastNeed,
  required void Function(FerretEngine engine) onEngine,
}) async {
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

  final discovery = FerretDiscovery.forPlatform();
  final engine = await FerretEngine.create(
    secrets: secrets,
    settings: settings,
    device: device,
    features: [for (final feature in features) feature.feature],
    discovery: discovery,
    sameAccount: SameAccount(siblingSecrets: [paths.cli.secrets]),
    multicastNeed: multicastNeed,
  );
  onEngine(engine);
  final localNetwork = await _localNetworkAsk(discovery, engine, settings);
  sharedComputer.follow(engine, computerName: described.name);
  await engine.start();
  final quit = AppQuit(shutdown: engine.shutdown)..start();

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
  if (Platform.isAndroid || Platform.isIOS) {
    unawaited(
      PairLinks.forApp(
        featureContext.navigatorKey,
        (link) => LinkPairPage(link: link),
      ).start(),
    );
  }
  final featureWindows = FeatureWindowHost(menubar: ferretMenubar);
  featureContext
    ..windows = featureWindows
    ..localNetwork = localNetwork
    ..quit = quit.quit;
  if (ferretMenubar.isSupported) {
    featureContext
      ..dragOut = MenubarDragOut(ferretMenubar)
      ..quickLook = ferretMenubar.toggleQuickLook
      ..systemDrags = MenubarSystemDrags(ferretMenubar);
  }
  final floatingPanel = switch (ferretMenubar.isSupported) {
    true => FloatingPanelHost(menubar: ferretMenubar),
    false => null,
  };
  featureContext.floatingPanel = floatingPanel;
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
    quit: quit,
  );
  await menubar.start();
  await DesktopBinding(
    host: host,
    pause: pause,
    settings: settings,
    notifier: notifier,
    quit: quit,
  ).start();

  final app = FerretApp(
    host: host,
    pause: pause,
    features: features,
    featureContext: featureContext,
    menubar: menubar.menubar,
    navigation: navigation,
    featureWindows: featureWindows,
    floatingPanel: floatingPanel,
    quit: quit,
    views: switch (ferretMenubar.isSupported) {
      true => views,
      false => null,
    },
  );
  onStarted?.call(engine);

  return app;
}

/// On an iPhone, discovery waits for the person unless they went on
/// before or something is paired. Elsewhere nothing asks.
Future<LocalNetworkAsk?> _localNetworkAsk(
  Discovery discovery,
  FerretEngine engine,
  SettingsStore settings,
) async {
  if (discovery is! HeldDiscovery) {
    return null;
  }

  bool hasDevices() => engine.trustStore.devices.isNotEmpty;
  if (LocalNetworkAsk.releasedAtLaunch(settings, hasDevices: hasDevices())) {
    await discovery.release();
  }

  return LocalNetworkAsk(
    settings: settings,
    held: discovery,
    hasDevices: hasDevices,
    deviceChanges: engine.trustStore.changes,
  );
}
