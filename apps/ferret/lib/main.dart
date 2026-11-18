import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:ferret/wiring/call_media_pause.dart';
import 'package:find/find.dart';
import 'package:handoff/handoff.dart';
import 'package:media/media.dart';
import 'package:messages/messages.dart';
import 'package:notifications/notifications.dart';
import 'package:power/power.dart';
import 'package:shell/shell.dart';

Future<void> main() => runFerret(
  features: [
    CallsFeatureUi(),
    ClipboardFeatureUi(),
    DropFeatureUi(),
    FindFeatureUi(),
    HandoffFeatureUi(),
    MediaFeatureUi(),
    MessagesFeatureUi(),
    NotificationsFeatureUi(),
    PowerFeatureUi(),
  ],
  appVersion: '0.1.0',
  onStarted: CallMediaPause.attach,
);
