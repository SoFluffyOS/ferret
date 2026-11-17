import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:handoff/handoff.dart';
import 'package:media/media.dart';
import 'package:notifications/notifications.dart';
import 'package:shell/shell.dart';

Future<void> main() => runFerret(
  features: [
    ClipboardFeatureUi(),
    DropFeatureUi(),
    HandoffFeatureUi(),
    MediaFeatureUi(),
    NotificationsFeatureUi(),
  ],
  appVersion: '0.1.0',
);
