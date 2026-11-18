import 'package:ferret_mirroring/ferret_mirroring.dart';

/// How a screen reaches this computer, in the words people use for it.
enum MirrorWay {
  wifi,
  cable,
  airplay;

  static const _airplayRouteId = 'airplay';

  static MirrorWay of(MirrorTarget target) {
    if (target.routeId == _airplayRouteId) {
      return .airplay;
    }

    if (target.wireless) {
      return .wifi;
    }

    return .cable;
  }
}
