import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_system',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_system/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_system'),
  ),
)
@HostApi()
abstract class SystemHostApi {
  /// Lets the app receive multicast packets (Android drops them otherwise).
  void acquireMulticastLock();

  void releaseMulticastLock();

  bool isMulticastLockHeld();
}
