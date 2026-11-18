import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:mirroring/models/setup_help.dart';

/// Where showing a phone over a cable stands on this computer: the step
/// that is still missing, or none once a phone is ready.
class CableSetup {
  const CableSetup({this.step, this.detail, this.help = .none});

  /// Nothing is missing.
  static const ready = CableSetup();

  /// Null once a phone answers and has allowed this computer.
  final RouteSetup? step;

  /// What the route said next to the step: the phone's name while it
  /// waits for Allow.
  final String? detail;

  final SetupHelp help;

  bool get isReady => step == null;

  @override
  bool operator ==(Object other) =>
      other is CableSetup &&
      other.step == step &&
      other.detail == detail &&
      other.help == help;

  @override
  int get hashCode => Object.hash(step, detail, help);
}
