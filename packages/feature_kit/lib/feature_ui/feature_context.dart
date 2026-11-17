import 'package:engine/engine.dart';
import 'package:feature_kit/services/services.dart';
import 'package:flutter/widgets.dart';

/// What the app hands a [FeatureUi]: the running engine, and a way to show
/// things in the app's navigator.
class FeatureContext {
  const FeatureContext({
    required this.engine,
    required this.navigatorKey,
    required this.notifier,
  });

  final FerretEngine engine;

  /// Shows system notifications on this device.
  final LocalNotifier notifier;
  final GlobalKey<NavigatorState> navigatorKey;

  /// Opens [page] on top of the app, such as a file picker result or a
  /// conversation.
  Future<T?> push<T>(Widget page) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return null;
    }

    return navigator.push(PageRouteBuilder<T>(pageBuilder: (_, _, _) => page));
  }
}
