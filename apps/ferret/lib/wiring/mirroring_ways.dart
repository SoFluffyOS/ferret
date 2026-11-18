import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:mirroring/mirroring.dart';

/// Screen mirroring with every way a screen can arrive plugged in: a phone
/// with debugging on, and an iPhone that picks this computer in Control
/// Center. The packages never import the feature, so the app joins them.
abstract final class MirroringWays {
  static MirroringFeatureUi create() {
    late final MirroringFeatureUi mirroring;
    final onComputer =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    mirroring = MirroringFeatureUi(
      routes: [
        ScrcpyRoute(
          toolsDirectory: () async {
            final paths = await AppPaths.get();
            return paths.create(paths.tools);
          },
        ),
      ],
      receivers: [
        if (onComputer)
          AirPlayReceiver(
            // Asked for when the receiver starts, long after the engine
            // loaded this device's key. Phones see the same receiver on
            // every run, and nobody else can make it.
            identity: () async => AirPlayIdentity.derive(
              await mirroring.feature.host.identity.keyPair
                  .extractPrivateKeyBytes(),
            ),
          ),
      ],
    );
    return mirroring;
  }
}
