import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:ferret/wiring/call_media_pause.dart';
import 'package:find/find.dart';
import 'package:handoff/handoff.dart';
import 'package:iphone/iphone.dart';
import 'package:media/media.dart';
import 'package:messages/messages.dart';
import 'package:mirroring/mirroring.dart';
import 'package:notifications/notifications.dart';
import 'package:power/power.dart';
import 'package:remote_input/remote_input.dart';
import 'package:shell/shell.dart';

Future<void> main() => runFerret(
  features: [
    CallsFeatureUi(),
    ClipboardFeatureUi(),
    DropFeatureUi(),
    FindFeatureUi(),
    HandoffFeatureUi(),
    IphoneFeatureUi(),
    MediaFeatureUi(),
    MessagesFeatureUi(),
    MirroringFeatureUi(),
    NotificationsFeatureUi(),
    PowerFeatureUi(),
    RemoteInputFeatureUi(),
  ],
  appVersion: '0.1.0',
  onStarted: CallMediaPause.attach,
);
