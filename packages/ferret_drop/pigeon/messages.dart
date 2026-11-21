import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_drop',
    dartOut: 'lib/src/messages.g.dart',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'ferret_drop'),
    gobjectHeaderOut: 'linux/messages.g.h',
    gobjectSourceOut: 'linux/messages.g.cc',
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_drop/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_drop'),
    swiftOut: [
      'ios/ferret_drop/Sources/ferret_drop/Messages.g.swift',
      'macos/ferret_drop/Sources/ferret_drop/Messages.g.swift',
    ],
  ),
)
/// Files or text another app shared with "Send with Ferret". [paths] are
/// file paths, or on Android `content://` URIs read while sending.
class SharedItems {
  SharedItems({
    required this.paths,
    this.text,
    this.deviceId,
    this.everyDevice,
    this.keepFiles,
  });

  List<String> paths;
  String? text;

  /// The device picked in the share sheet, where the sheet lists Ferret's
  /// devices (the macOS Share menu). Null when none was picked there.
  String? deviceId;

  /// True when "All my devices" was picked in the share sheet.
  bool? everyDevice;

  /// True when [paths] are the files themselves, which must stay where they
  /// are. Otherwise they are copies to delete, or URIs to let go, once sent.
  bool? keepFiles;
}

/// A device the system's share sheet can offer, where the sheet lists them.
class ShareTarget {
  ShareTarget({required this.deviceId, required this.name, required this.kind});

  String deviceId;
  String name;

  /// What to draw next to the name: "phone", "tablet", "laptop" or "desktop".
  String kind;
}

/// A file saved into the shared Downloads collection.
class SavedFile {
  SavedFile({required this.location, required this.name});

  /// Where to open it later: a `content://` URI or a file path.
  String location;

  /// The name it got, which may differ when the wanted one was taken.
  String name;
}

@HostApi()
abstract class FerretDropHostApi {
  /// Shares that arrived before Dart was listening. Each one is returned once.
  List<SharedItems> takePendingShares();

  /// The connected devices the share sheet may offer. Does nothing where
  /// the sheet can't list devices.
  void setShareTargets(List<ShareTarget> targets);

  /// Whether [saveToDownloads] works here (Android 10 and newer).
  bool canSaveToDownloads();

  /// Moves [sourcePath] into Downloads/[folder] through MediaStore, never
  /// overwriting: a taken name becomes "name (1).ext".
  @async
  SavedFile saveToDownloads(
    String sourcePath,
    String fileName,
    String mimeType,
    String folder,
  );

  /// Opens a received file in its default app. Returns false when nothing
  /// could open it.
  bool open(String location, String mimeType);

  /// Shows a received file in Finder, Explorer, the file manager or the
  /// Downloads app. Returns false when that isn't possible here.
  bool reveal(String location);
}

@FlutterApi()
abstract class FerretDropFlutterApi {
  /// Another app shared files or text while Ferret was running.
  void onShared(SharedItems items);
}
