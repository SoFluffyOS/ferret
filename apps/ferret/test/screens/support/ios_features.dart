// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:typed_data';

import 'package:actions/actions.dart';
import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_camera/ferret_camera.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:find/find.dart';
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

/// Every feature `lib/main.dart` registers, as the iPhone build makes them.
///
/// Tests run on a macOS host, where `dart:io`'s `Platform` says macOS
/// whatever `debugDefaultTargetPlatformOverride` says. So each feature that
/// asks `Platform` gets the iPhone's answer here: no notification, text or
/// call source, no Quick Share, no screen to share or view, no extra
/// display, no Bluetooth iPhone link, no browser bridge, no power-ups, no
/// media to share, a clipboard read only on request, and a camera and a
/// photo library. The same list serves an iPhone rig and an iPhone paired
/// with a computer rig, so the computer sees what an iPhone offers.
List<FeatureUi> iosFeatures() => [
  ActionsFeatureUi(feature: safeActionsFeature(offersActions: false)),
  CallsFeatureUi.withFeature(CallsFeature()),
  CameraFeatureUi(feature: CameraFeature(camera: const IphoneCamera())),
  ClipboardFeatureUi(
    feature: ClipboardFeature(clipboard: IphoneClipboard.new),
  ),
  DropFeatureUi(
    feature: DropFeature(
      quickShareOptions: const QuickShareOptions(supported: false),
    ),
  ),
  FindFeatureUi(platform: .ios),
  HandoffFeatureUi(
    handoff: FerretHandoff(isMacOS: false),
    browserBridge: false,
  ),
  IphoneFeatureUi(feature: IphoneFeature(isSupported: false)),
  MediaFeatureUi(platform: .ios),
  MessagesFeatureUi.withFeature(MessagesFeature()),
  MirroringFeatureUi(
    feature: MirroringFeature(
      canShare: false,
      canShareCamera: false,
      canView: false,
      canExtend: false,
      canBeDisplay: false,
    ),
  ),
  NotificationsFeatureUi.withFeature(NotificationsFeature()),
  PhotosFeatureUi(feature: PhotosFeature(library: const IphoneLibrary())),
  PowerFeatureUi(onPhone: false),
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

/// The iPhone's clipboard: read only when the person asks, and never
/// watched. Holds nothing, so a render never shows this Mac's clipboard.
class IphoneClipboard implements ClipboardPlatform {
  @override
  ClipboardAccess get access => .onRequest;

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

/// The iPhone's camera with its document scanner. Never opens: a render
/// stops at the request.
class IphoneCamera implements PhoneCamera {
  const IphoneCamera();

  @override
  bool get isSupported => true;

  @override
  bool get scansDocuments => true;

  @override
  Future<CameraAbilities> abilities() async =>
      const CameraAbilities(photo: true, document: true);

  @override
  Future<CameraCapture> takePhoto() => Completer<CameraCapture>().future;

  @override
  Future<CameraCapture> scanDocument() => Completer<CameraCapture>().future;
}

/// The iPhone's photo library, allowed and empty.
class IphoneLibrary implements PhotoLibrary {
  const IphoneLibrary();

  @override
  bool get isSupported => true;

  @override
  Future<PhotoLibraryAccess> access() async => .full;

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
