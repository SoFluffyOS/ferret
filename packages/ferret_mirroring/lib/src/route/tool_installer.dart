import 'package:ferret_mirroring/src/route/mirror_route.dart';

/// A [MirrorRoute] that can fetch the helper tool its
/// [RouteSetup.installTool] step asks for, such as adb.
abstract interface class ToolInstaller implements MirrorRoute {
  /// Whether [installTool] helps on this computer. Offer it only then.
  bool get canInstallTool;

  /// The [RouteNeedsSetup.detail] that means the tool is here but this app
  /// can't start it: the user has to, and a download wouldn't help.
  String get toolNotStartedDetail;

  /// Downloads the tool. Call it only from a button the user pressed,
  /// whose words say what is downloaded and from where. Throws when the
  /// download fails.
  Future<void> installTool();
}
