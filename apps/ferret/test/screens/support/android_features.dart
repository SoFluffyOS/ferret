// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:async';
import 'dart:typed_data';

import 'package:actions/actions.dart';
import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:ferret_camera/ferret_camera.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:ferret_handoff/src/messages.g.dart' show HandoffHostApi;
import 'package:ferret_media/ferret_media.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:ferret_phone_control/testing.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:ferret_power/testing.dart';
import 'package:find/find.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:iphone/iphone.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:media/media.dart';
import 'package:messages/messages.dart';
import 'package:mirroring/mirroring.dart';
import 'package:notifications/notifications.dart';
import 'package:phone_camera/phone_camera.dart';
import 'package:photos/photos.dart';
import 'package:power/power.dart';
import 'package:remote_input/remote_input.dart';
import 'package:scripting/scripting.dart';
import 'package:wake/wake.dart';

import 'action_fakes.dart';
import 'mirror_fakes.dart';
import 'phone_fakes.dart';

/// Every feature `lib/main.dart` registers, as the Android build makes them.
///
/// Tests run on a macOS host, where `dart:io`'s `Platform` says macOS
/// whatever `debugDefaultTargetPlatformOverride` says. So each feature that
/// asks `Platform` gets the Android answer here: a phone with a SIM whose
/// notification, text, call and media access are still off, Quick Share
/// off by default, a screen and camera to share (never to view), the
/// share sheet and assistant, power-ups, a clipboard read only in front,
/// received files in Download › Ferret, a camera without a document
/// scanner, a photo library nobody asked about yet, and no Bluetooth iPhone
/// link, browser page, computer actions or keyboard sharing. The same list
/// serves an Android phone or tablet rig and an Android phone paired with a
/// computer rig, so the computer sees what a Pixel offers.
List<FeatureUi> androidFeatures() => [
  ActionsFeatureUi(feature: safeActionsFeature(offersActions: false)),
  CallsFeatureUi.withFeature(CallsFeature(phone: AndroidCalls())),
  CameraFeatureUi(feature: CameraFeature(camera: const AndroidCamera())),
  ClipboardFeatureUi(
    feature: ClipboardFeature(clipboard: AndroidClipboard.new),
  ),
  DropFeatureUi(
    feature: DropFeature(
      quickShareOptions: const QuickShareOptions(
        supported: false,
        onComputer: false,
      ),
    ),
    describeFolder: () async => 'Download/Ferret',
  ),
  FindFeatureUi(platform: .android),
  HandoffFeatureUi(
    handoff: FerretHandoff(
      api: AndroidHandoffApi(),
      isAndroid: true,
      isMacOS: false,
      isIOS: false,
    ),
    browserBridge: false,
  ),
  IphoneFeatureUi(feature: IphoneFeature(isSupported: false)),
  MediaFeatureUi(
    platform: .android,
    feature: MediaFeature(backend: AndroidMedia.new),
  ),
  MessagesFeatureUi.withFeature(MessagesFeature(source: OffSmsSource())),
  MirroringFeatureUi(
    feature: MirroringFeature(
      capture: PhoneScreenCapture.new,
      camera: StillCamera.new,
      phoneControl: () => PhoneControl(
        power: PowerCapabilities.withPlatform(FakePowerPlatform()),
        service: FakeControlService(),
        supported: true,
      ),
      canShare: true,
      canShareCamera: true,
      canView: false,
      canExtend: false,
      canBeDisplay: true,
    ),
  ),
  NotificationsFeatureUi.withFeature(
    NotificationsFeature(source: OffNotificationSource()),
    access: OffNotificationSource(),
  ),
  PhotosFeatureUi(feature: PhotosFeature(library: const AndroidLibrary())),
  PowerFeatureUi(onPhone: true),
  RemoteInputFeatureUi(
    feature: RemoteInputFeature(
      canBeControlled: false,
      canControl: true,
      canSwitchScreens: false,
      locker: const NoLocker(),
    ),
  ),
  ScriptingFeatureUi(),
  ShelfFeatureUi(),
  WakeFeatureUi(feature: WakeFeature(isComputer: false)),
];

/// [features] with each of [others] in place of the feature with its id,
/// or added when there is none.
List<FeatureUi> withFeatures(
  List<FeatureUi> features,
  List<FeatureUi> others,
) {
  final ids = {for (final other in others) other.featureId};
  return [
    for (final feature in features)
      if (!ids.contains(feature.featureId)) feature,
    ...others,
  ];
}

/// Android's clipboard: read while Ferret is in front. Holds nothing, so a
/// render never shows this Mac's clipboard.
class AndroidClipboard implements ClipboardPlatform {
  @override
  ClipboardAccess get access => .foreground;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<ClipboardContent?> read() async => null;

  @override
  Future<void> write(ClipboardContent content) async {}

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}
}

/// A phone with a SIM whose call permissions aren't given yet. Never
/// places or answers a call.
class AndroidCalls implements PhoneCalls {
  static PlatformCallPermissions get _off => PlatformCallPermissions(
    phoneState: false,
    callLog: false,
    contacts: false,
    answerCalls: false,
    placeCalls: false,
    canAskAgain: true,
  );

  @override
  Stream<PlatformPhoneEvent> get events => const Stream.empty();

  @override
  Future<PlatformCallPermissions> permissions() async => _off;

  @override
  Future<PlatformCallPermissions> requestPermissions() async => _off;

  @override
  Future<bool> hasTelephony() async => true;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<bool> startMonitoring() async => false;

  @override
  Future<void> stopMonitoring() async {}

  @override
  Future<List<PlatformCallLogEntry>> recentCalls(int limit) async => const [];

  @override
  Future<PlatformContact?> lookupContact(String number) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Screens never place or answer calls.');
}

/// The phone's camera app, without a document scanner. Never opens: a
/// render stops at the request.
class AndroidCamera implements PhoneCamera {
  const AndroidCamera();

  @override
  bool get isSupported => true;

  @override
  bool get scansDocuments => false;

  @override
  Future<CameraAbilities> abilities() async =>
      const CameraAbilities(photo: true, document: false);

  @override
  Future<CameraCapture> takePhoto() => Completer<CameraCapture>().future;

  @override
  Future<CameraCapture> scanDocument() => Completer<CameraCapture>().future;
}

/// The phone's photo library before anyone asked for it.
class AndroidLibrary implements PhotoLibrary {
  const AndroidLibrary();

  @override
  bool get isSupported => true;

  @override
  Future<PhotoLibraryAccess> access() async => .notAsked;

  @override
  Future<PhotoLibraryAccess> requestAccess() async => .full;

  @override
  Future<PhotoPage> list({String? cursor, int limit = 60}) async =>
      PhotoPage.empty;

  @override
  Future<Uint8List?> thumbnail(String id, {required int maxPx}) async => null;

  @override
  Future<String?> export(String id) async => null;

  @override
  Stream<PhotoEntry> get newScreenshots => const Stream.empty();

  @override
  Future<bool> openSettings() async => false;
}

/// The phone's media players before Notification access is on.
class AndroidMedia implements MediaBackend {
  @override
  Stream<List<PlayerInfo>> get players => const Stream.empty();

  @override
  Stream<MediaAccess> get accessChanges => const Stream.empty();

  @override
  Future<MediaAccess> access() async => .notGranted;

  @override
  Future<MediaAccess> requestAccess() async => .notGranted;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}

  @override
  Future<List<PlayerInfo>> currentPlayers() async => const [];

  @override
  Future<bool> command(
    String playerId,
    PlayerAction action, {
    int positionMs = 0,
    double volume = 0,
  }) async => false;
}

/// The share sheet and assistant on Android, with nothing shared and
/// Ferret not the assistant.
class AndroidHandoffApi extends Fake implements HandoffHostApi {
  @override
  Future<void> setDevices(List<HandoffDevice> devices) async {}

  @override
  Future<List<SharedItem>> takePending() async => const [];

  @override
  Future<bool> openInApp(String uri, String appId) async => false;

  @override
  Future<bool> isAssistantEnabled() async => false;

  @override
  Future<void> openAssistantSettings() async {}
}
