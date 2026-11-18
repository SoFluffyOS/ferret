import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_clipboard',
    dartOut: 'lib/src/messages.g.dart',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'ferret_clipboard'),
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_clipboard/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_clipboard'),
    swiftOut: [
      'ios/ferret_clipboard/Sources/ferret_clipboard/Messages.g.swift',
      'macos/ferret_clipboard/Sources/ferret_clipboard/Messages.g.swift',
    ],
  ),
)
/// What the clipboard holds. Only one of [text] or [image] is set.
class PlatformClip {
  PlatformClip({
    this.text,
    this.image,
    this.imageMime,
    required this.sensitive,
  });

  String? text;
  Uint8List? image;
  String? imageMime;

  /// The source app marked it as private (a concealed or transient type on
  /// macOS, `EXTRA_IS_SENSITIVE` on Android, the history and monitor
  /// exclusion formats on Windows).
  bool sensitive;
}

@HostApi()
abstract class ClipboardHostApi {
  /// The current clipboard, or null when it is empty, holds something other
  /// than text or an image, or can't be read right now.
  PlatformClip? read();

  /// Replaces the clipboard. With `sensitive`, marks it so clipboard managers
  /// and history skip it.
  void write(PlatformClip clip);

  /// Starts reporting changes through [ClipboardFlutterApi.onChanged].
  void startWatching();

  void stopWatching();
}

@FlutterApi()
abstract class ClipboardFlutterApi {
  /// The clipboard changed. Read it to see what it holds.
  void onChanged();
}
