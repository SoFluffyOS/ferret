import 'dart:async';
import 'dart:io';

import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:ferret/wiring/wiring.dart';
import 'package:find/find.dart';
import 'package:handoff/handoff.dart';
import 'package:iphone/iphone.dart';
import 'package:media/media.dart';
import 'package:messages/messages.dart';
import 'package:notifications/notifications.dart';
import 'package:power/power.dart';
import 'package:remote_input/remote_input.dart';
import 'package:shell/shell.dart';

Future<void> main(List<String> arguments) async {
  final send = await SendCommand.read(arguments);

  await runFerret(
    features: [
      CallsFeatureUi(),
      ClipboardFeatureUi(),
      DropFeatureUi(filesToSend: send.files, handoff: send.handoff),
      FindFeatureUi(),
      HandoffFeatureUi(),
      IphoneFeatureUi(),
      MediaFeatureUi(),
      MessagesFeatureUi(),
      MirroringWays.create(),
      NotificationsFeatureUi(),
      PowerFeatureUi(),
      RemoteInputFeatureUi(),
    ],
    appVersion: '0.1.0',
    onStarted: (engine) {
      CallMediaPause.attach(engine);
      unawaited(
        CliControl.attach(
          engine,
          isComputer:
              Platform.isMacOS || Platform.isWindows || Platform.isLinux,
        ),
      );
    },
  );
}
