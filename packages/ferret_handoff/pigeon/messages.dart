import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_handoff',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_handoff/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_handoff'),
    swiftOut: [
      'ios/ferret_handoff/Sources/ferret_handoff/Messages.g.swift',
      'macos/ferret_handoff/Sources/ferret_handoff/Messages.g.swift',
    ],
  ),
)
/// Where a shared item came from.
enum ShareOrigin {
  /// The share sheet: Send with Ferret, then "Open on…".
  shareSheet,

  /// The Android assistant, reading what is on screen.
  assistant,
}

/// Something the user asked to continue on another device, picked outside
/// Flutter (share sheet or assistant).
class SharedItem {
  SharedItem({
    required this.origin,
    required this.createdAtMs,
    this.targetDeviceId,
    this.text,
    this.subject,
    this.webUri,
    this.deepLink,
    this.appPackage,
    this.appName,
    this.structuredData,
    this.title,
  });

  ShareOrigin origin;

  /// The device picked in the native chooser, or null to pick in Flutter.
  String? targetDeviceId;

  /// Shared text, which may be or contain a URL.
  String? text;
  String? subject;

  /// From the assistant: `AssistContent.getWebUri()`.
  String? webUri;

  /// From the assistant: the data URI of `AssistContent.getIntent()`.
  String? deepLink;
  String? appPackage;
  String? appName;

  /// From the assistant: `AssistContent.getStructuredData()`, JSON-LD.
  String? structuredData;

  /// From the assistant: the window title.
  String? title;
  int createdAtMs;
}

/// A device the native chooser can offer.
class HandoffDevice {
  HandoffDevice({required this.id, required this.name});

  String id;
  String name;
}

/// The page shown in a desktop browser.
class BrowserTab {
  BrowserTab({
    required this.url,
    required this.title,
    required this.browserBundleId,
    required this.browserName,
  });

  String url;
  String title;
  String browserBundleId;
  String browserName;
}

/// Whether Ferret may ask the browser for its current page (macOS Automation).
enum BrowserAccess {
  granted,
  denied,

  /// macOS will ask the first time.
  notDetermined,

  /// No supported browser is running.
  noBrowser,

  /// This platform can't read browser tabs.
  unsupported,
}

@HostApi()
abstract class HandoffHostApi {
  /// The connected devices the native chooser and assistant offer.
  void setDevices(List<HandoffDevice> devices);

  /// Items shared while Flutter wasn't running, oldest first. Taking them
  /// removes them.
  List<SharedItem> takePending();

  /// Opens [uri] in the app [appId] (Android package or macOS bundle id).
  /// False when that app isn't installed or can't take the URI.
  @async
  bool openInApp(String uri, String appId);

  /// Android: whether Ferret is the default digital assistant.
  bool isAssistantEnabled();

  /// Android: opens the system screen to pick the default assistant.
  void openAssistantSettings();

  /// macOS: the current page of the frontmost (or last used) browser. Asks
  /// for Automation permission the first time.
  @async
  BrowserTab? currentBrowserTab();

  /// macOS: whether reading the browser's page is allowed, without asking.
  /// Async: macOS can take a while to answer, so it never runs on the main
  /// thread.
  @async
  BrowserAccess browserAccess();

  /// macOS: reports when the user leaves a browser, so its page can be
  /// suggested on other devices.
  void setBrowserWatch(bool enabled);
}

@FlutterApi()
abstract class HandoffEventsApi {
  /// The user shared [item]; answer true once it was sent.
  @async
  bool onShared(SharedItem item);

  /// The user switched away from the browser [bundleId].
  void onBrowserDeactivated(String bundleId);
}
