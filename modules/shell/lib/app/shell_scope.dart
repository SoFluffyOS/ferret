import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// The features and context the shell hosts, for pages to read.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.features,
    required this.featureContext,
    required super.child,
  });

  final List<FeatureUi> features;
  final FeatureContext featureContext;

  static ShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    if (scope == null) {
      throw FlutterError('No ShellScope above this widget.');
    }

    return scope;
  }

  /// The scope, or null where there is none, such as a menu shown on its
  /// own.
  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  /// Reads the scope without depending on it, such as in `initState`.
  static ShellScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ShellScope>();
    if (scope == null) {
      throw FlutterError('No ShellScope above this widget.');
    }

    return scope;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      features != oldWidget.features ||
      featureContext != oldWidget.featureContext;
}
