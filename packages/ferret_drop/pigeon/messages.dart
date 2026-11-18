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
/// Files or text another app shared with "Send with Ferret". Files are
/// already copied to the app's cache, so [paths] are plain file paths.
class SharedItems {
  SharedItems({required this.paths, this.text});

  List<String> paths;
  String? text;
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
