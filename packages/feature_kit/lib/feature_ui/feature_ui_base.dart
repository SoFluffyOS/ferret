import 'package:engine/engine.dart';
import 'package:feature_kit/feature_ui/feature_context.dart';
import 'package:feature_kit/services/services.dart';
import 'package:flutter/widgets.dart';

/// The app side of a feature. The shell shows each feature's pieces in fixed
/// places, so features never touch the shell's code.
abstract class FeatureUi {
  /// Same id as the engine [Feature].
  String get featureId;

  /// The engine side, registered with the engine at startup.
  Feature get feature;

  /// The feature's own strings, added to the app's localizations.
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [];

  /// The notice action sets this feature uses, registered at startup.
  List<NoticeCategory> get noticeCategories => const [];

  /// Called once after the engine started, such as to ask for a permission
  /// or start a platform listener.
  Future<void> onAppStarted(FeatureContext context) async {}

  /// The feature's name as people see it, such as "Clipboard".
  String title(BuildContext context);

  IconData get icon;

  /// A card on the home screen (the menubar popover on macOS), or null.
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) => null;

  /// Actions for one connected device, such as "Send a file", or empty.
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => const [];

  /// The feature's section in Settings, or null.
  Widget? buildSettings(BuildContext context, FeatureContext feature) => null;

  /// Files dropped on the app or on the menubar icon. Return true when the
  /// feature took them.
  Future<bool> onFilesDropped(
    FeatureContext feature,
    List<String> paths,
  ) async => false;
}

/// Something a person can do with a feature, shown as a button.
class FeatureAction {
  const FeatureAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}
