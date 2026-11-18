import 'package:pigeon/pigeon.dart';

// Regenerate with `fvm dart run pigeon --input pigeon/messages.dart` from the
// package folder. Watching and controlling phone calls is Android only.
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_calls',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_calls/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_calls'),
  ),
)
/// The phone's call state as Android's telephony service reports it.
enum PlatformPhoneState {
  /// No call.
  idle,

  /// A call is ringing. With a call already going on, it is a call waiting.
  ringing,

  /// At least one call is dialing, active or on hold.
  offHook,
}

/// How a call command went.
enum PlatformCallResult {
  ok,

  /// The runtime permission the command needs is not granted.
  permissionMissing,

  /// This Android version has no API for it.
  unsupported,

  /// Android refused, or nothing was there to act on.
  failed,
}

/// What a call log entry was. Mirrors `CallLog.Calls.TYPE`.
enum PlatformCallLogType { incoming, outgoing, missed, rejected }

/// Which of the runtime permissions the app holds.
class PlatformCallPermissions {
  PlatformCallPermissions({
    required this.phoneState,
    required this.callLog,
    required this.contacts,
    required this.answerCalls,
    required this.placeCalls,
    required this.canAskAgain,
  });

  /// `READ_PHONE_STATE`: see that a call is ringing or going on.
  bool phoneState;

  /// `READ_CALL_LOG`: see the number, and read recent calls.
  bool callLog;

  /// `READ_CONTACTS`: turn a number into a name and a photo.
  bool contacts;

  /// `ANSWER_PHONE_CALLS`: answer and end calls. Always false before
  /// Android 8.
  bool answerCalls;

  /// `CALL_PHONE`: place calls.
  bool placeCalls;

  /// False when Android will no longer show the permission dialog for a
  /// missing permission, so only the app's settings page can grant it.
  bool canAskAgain;
}

/// A change in the phone's call state.
class PlatformPhoneEvent {
  PlatformPhoneEvent({required this.state, this.number});

  PlatformPhoneState state;

  /// The other side's number, or null when Android did not say (hidden
  /// number, missing permission, or not known yet).
  String? number;
}

/// A number found in the phone's contacts.
class PlatformContact {
  PlatformContact({required this.name, this.photoJpeg});

  String name;

  /// The contact's photo as a JPEG, at most 96 pixels a side.
  Uint8List? photoJpeg;
}

/// One entry of the phone's call history.
class PlatformCallLogEntry {
  PlatformCallLogEntry({
    required this.id,
    required this.number,
    required this.name,
    required this.type,
    required this.dateMs,
    required this.durationSeconds,
  });

  String id;
  String number;

  /// The contact's name, empty when unknown.
  String name;
  PlatformCallLogType type;
  int dateMs;
  int durationSeconds;
}

@HostApi()
abstract class CallsHostApi {
  PlatformCallPermissions getPermissions();

  /// Shows Android's permission dialogs for what is missing and returns the
  /// permissions afterwards. Needs the app on screen; without an activity it
  /// returns the current permissions unchanged.
  @async
  PlatformCallPermissions requestPermissions();

  /// Opens this app's page in system settings, where permissions that can no
  /// longer be asked for are granted.
  void openAppSettings();

  /// Starts reporting call state through [CallsFlutterApi.onPhoneEvent],
  /// beginning with the current state. Returns false when `READ_PHONE_STATE`
  /// is missing.
  bool startMonitoring();

  void stopMonitoring();

  /// Answers the ringing call.
  PlatformCallResult answer();

  /// Declines the ringing call or hangs up the ongoing one.
  PlatformCallResult end();

  /// Stops the ringtone of the ringing call until it stops ringing.
  PlatformCallResult silenceRinger();

  /// Calls [number] with the default SIM, without bringing this app forward.
  PlatformCallResult dial(String number);

  /// The newest [limit] entries of the call history. Empty without
  /// `READ_CALL_LOG`.
  @async
  List<PlatformCallLogEntry> recentCalls(int limit);

  /// The contact whose number is [number], or null when there is none or
  /// `READ_CONTACTS` is missing.
  @async
  PlatformContact? lookupContact(String number);
}

@FlutterApi()
abstract class CallsFlutterApi {
  void onPhoneEvent(PlatformPhoneEvent event);
}
