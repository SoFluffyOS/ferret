import 'package:pigeon/pigeon.dart';

// This file is where you define the interface between Dart code and host
// platform code. After editing this file, run
//   dart run pigeon --input pigeon/messages.dart
// to re-generate all of the output files.
//
// If you add new platforms to your plugin, add the corresponding output
// options in the PigeonOptions below.
//
// To learn more about Pigeon, see https://pub.dev/packages/pigeon.

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_remote_input',
    dartOut: 'lib/src/messages.g.dart',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'ferret_remote_input'),
    gobjectHeaderOut: 'linux/messages.g.h',
    gobjectSourceOut: 'linux/messages.g.cc',
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_remote_input/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_remote_input'),
    swiftOut: [
      'ios/ferret_remote_input/Sources/ferret_remote_input/Messages.g.swift',
      'macos/ferret_remote_input/Sources/ferret_remote_input/Messages.g.swift',
    ],
  ),
)
@HostApi()
abstract class FerretRemoteInputPluginApi {
  /// Returns the system version of the host platform.
  String getPlatformVersion();
}
