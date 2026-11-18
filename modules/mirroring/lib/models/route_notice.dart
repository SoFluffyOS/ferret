import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:mirroring/models/setup_help.dart';

/// A way to show a screen that isn't ready on this computer yet, and the
/// step that makes it work.
class RouteNotice {
  const RouteNotice({
    required this.routeId,
    required this.step,
    this.detail,
    this.help = .none,
  });

  final String routeId;
  final RouteSetup step;

  /// Something the route said to show next to the step, such as a path.
  final String? detail;

  final SetupHelp help;

  @override
  bool operator ==(Object other) =>
      other is RouteNotice &&
      other.routeId == routeId &&
      other.step == step &&
      other.detail == detail &&
      other.help == help;

  @override
  int get hashCode => Object.hash(routeId, step, detail, help);
}
