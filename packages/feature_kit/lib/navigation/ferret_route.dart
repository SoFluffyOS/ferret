import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:feature_kit/theme/ferret_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show PredictiveBackPageTransitionsBuilder;

/// The route every Ferret page opens in. On iOS it slides in, and a swipe
/// from the left edge goes back, as in every iPhone app. On Android the
/// page follows the system back gesture (Android 14+): it shrinks and shows
/// the page behind while you swipe. Elsewhere the page shows at once: a
/// menubar popover or a computer window gains nothing from a slide.
Route<T> ferretRoute<T>(Widget page, {RouteSettings? settings}) =>
    switch (defaultTargetPlatform) {
      .iOS => CupertinoPageRoute<T>(builder: (_) => page, settings: settings),
      .android => AndroidPageRoute<T>(
        builder: (_) => page,
        settings: settings,
      ),
      _ => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (_, _, _) => page,
      ),
    };

/// Android's page route: Material's predictive back while the back gesture
/// is in progress, its fade-forward otherwise (a tap on Back, a push).
/// The fade shows Ferret's own background, not Material's.
class AndroidPageRoute<T> extends PageRoute<T> {
  AndroidPageRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  static const _timing = PredictiveBackPageTransitionsBuilder();

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _timing.transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => PredictiveBackPageTransitionsBuilder(
    fallbackColor: context.palette.background,
  ).buildTransitions(this, context, animation, secondaryAnimation, child);
}
