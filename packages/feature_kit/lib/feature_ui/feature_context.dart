import 'package:engine/engine.dart';
import 'package:feature_kit/navigation/navigation.dart';
import 'package:feature_kit/services/services.dart';
import 'package:flutter/widgets.dart';

/// What the app hands a [FeatureUi]: the running engine, and a way to show
/// things in the app's navigator.
class FeatureContext {
  FeatureContext({
    required this.engine,
    required this.navigatorKey,
    required this.notifier,
    Future<void> Function()? onReveal,
  }) : _onReveal = onReveal;

  final FerretEngine engine;

  /// Shows system notifications on this device.
  final LocalNotifier notifier;
  final GlobalKey<NavigatorState> navigatorKey;

  final Future<void> Function()? _onReveal;

  /// How [openSection] shows a section. The shell sets it once its views
  /// exist.
  Future<void> Function(String deviceId, String sectionId)? onOpenSection;

  /// Brings Ferret to the front (the menubar popover on macOS), such as when
  /// this device starts ringing.
  Future<void> reveal() async {
    final onReveal = _onReveal;
    if (onReveal == null) {
      return;
    }

    await onReveal();
  }

  /// Opens [page] on top of the app, such as a file picker result or a
  /// conversation.
  Future<T?> push<T>(Widget page) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return null;
    }

    return navigator.push(ferretRoute<T>(page));
  }

  /// Shows a section of the device [deviceId] (a `FeatureSection.id`):
  /// pushed on a phone, selected next to the device list in a window.
  Future<void> openSection(String deviceId, String sectionId) async {
    final onOpenSection = this.onOpenSection;
    if (onOpenSection == null) {
      return;
    }

    await onOpenSection(deviceId, sectionId);
  }
}
