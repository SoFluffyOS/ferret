import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/src/messages.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:handoff/handoff.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/handoff.dart';
import 'package:protocol/protocol.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

const pixel = HandoffPeer(
  id: 'pixel-id',
  name: 'Pixel',
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
);
const tablet = HandoffPeer(id: 'tablet-id', name: 'Tablet');

Activity webActivity(String id, {String title = 'A page'}) => Activity(
  id: id,
  kind: .ACTIVITY_KIND_WEB,
  title: title,
  uri: 'https://example.org/$id',
);

/// A clock tests move by hand.
class TestClock {
  DateTime now = DateTime(2026, 11, 18, 9);

  void advance(Duration by) => now = now.add(by);
}

/// A [FeatureHost] with no sessions, for testing a feature on its own.
class FakeHost implements FeatureHost {
  @override
  Presence get localPresence => Presence(batteryPercent: -1);

  @override
  Stream<Presence> get localPresenceChanges => const Stream.empty();

  FakeHost._(this.trustStore, this.settings);

  static Future<FakeHost> create([Map<String, Object?>? settings]) async =>
      FakeHost._(
        await TrustStore.open(MemorySecretStore()),
        MemorySettingsStore(settings),
      );

  @override
  final TrustStore trustStore;

  @override
  final SettingsStore settings;

  final StreamController<List<Session>> _sessionChanges = .broadcast();
  final List<GeneratedMessage> broadcasts = [];

  @override
  DeviceIdentity get identity => throw UnimplementedError();

  @override
  DeviceInfo get localDevice =>
      DeviceInfo(id: 'this-device', name: 'Mac', platform: .PLATFORM_MACOS);

  @override
  List<Session> get sessions => const [];

  /// The devices tests connected, by id.
  final Map<String, Session> connected = {};

  @override
  Session? sessionFor(String deviceId) => connected[deviceId];

  @override
  Stream<List<Session>> get sessionChanges => _sessionChanges.stream;

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async =>
      broadcasts.add(message);
}

class FakeOpener implements ActivityOpener {
  FakeOpener([this.result = .opened]);

  OpenResult result;
  final List<Activity> opened = [];

  @override
  Future<OpenResult> open(Activity activity) async {
    opened.add(activity);
    return result;
  }
}

class FakeNotifier implements LocalNotifier {
  final List<LocalNotice> shown = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast();

  void respond(NoticeResponse response) => _responses.add(response);

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(String id) async => cancelled.add(id);

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}

/// Platform calls answered from fields, recorded for checks.
class FakeHandoffApi implements HandoffHostApi {
  List<HandoffDevice> devices = [];
  List<SharedItem> pending = [];
  bool appInstalled = true;
  bool assistant = false;
  BrowserTab? tab;
  BrowserAccess access = .granted;
  bool? watching;
  final List<(String, String)> openedInApp = [];

  @override
  Future<void> setDevices(List<HandoffDevice> devices) async =>
      this.devices = devices;

  @override
  Future<List<SharedItem>> takePending() async {
    final taken = pending;
    pending = [];
    return taken;
  }

  @override
  Future<bool> openInApp(String uri, String appId) async {
    openedInApp.add((uri, appId));
    return appInstalled;
  }

  @override
  Future<bool> isAssistantEnabled() async => assistant;

  @override
  Future<void> openAssistantSettings() async {}

  @override
  Future<BrowserTab?> currentBrowserTab() async => tab;

  @override
  Future<BrowserAccess> browserAccess() async => access;

  @override
  Future<void> setBrowserWatch(bool enabled) async => watching = enabled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<HandoffFeature> startedFeature({
  FakeHost? host,
  ActivityOpener? opener,
  TestClock? clock,
}) async {
  final feature = HandoffFeature(
    opener: opener,
    clock: switch (clock) {
      final clock? => () => clock.now,
      null => null,
    },
  );
  await feature.start(host ?? await FakeHost.create());
  return feature;
}

/// Wraps [child] in the theme and localizations Handoff's widgets expect.
Widget testApp(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    HandoffLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: HandoffLocalizations.supportedLocales,
  builder: (context, _) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(style: const TextStyle(), child: child),
  ),
);
