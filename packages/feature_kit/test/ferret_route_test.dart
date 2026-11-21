import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _app() => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (context, _) => Navigator(
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          ferretRoute<void>(
            const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Center(child: Text('Second')),
            ),
          ),
        ),
        child: const Center(child: Text('First')),
      ),
    ),
  ),
);

/// The app's own navigator, the one Android's back gesture talks to, with
/// Home in the same route as every page, as the shell does on Android.
Widget _androidApp() => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) =>
      AndroidPageRoute<T>(builder: builder, settings: settings),
  home: Builder(
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).push(
        ferretRoute<void>(
          const ColoredBox(
            color: Color(0xFFFFFFFF),
            child: Center(child: Text('Second')),
          ),
        ),
      ),
      child: const Center(child: Text('First')),
    ),
  ),
  builder: (context, navigator) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: navigator ?? const SizedBox.shrink(),
  ),
);

Future<void> _backGesture(
  WidgetTester tester,
  String method,
  double progress,
) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
  'flutter/backgesture',
  const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, <String, Object?>{
      'touchOffset': <double>[5, 300],
      'progress': progress,
      'swipeEdge': 0,
    }),
  ),
  (_) {},
);

Future<bool> _swipeGoesBack(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.tap(find.text('First'));
  await tester.pumpAndSettle();
  await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
  await tester.pumpAndSettle();

  return find.text('Second').evaluate().isEmpty;
}

void main() {
  testWidgets('on iOS a swipe from the left edge goes back', (tester) async {
    debugDefaultTargetPlatformOverride = .iOS;
    final wentBack = await _swipeGoesBack(tester);
    debugDefaultTargetPlatformOverride = null;

    expect(wentBack, isTrue);
  });

  testWidgets('elsewhere a page opens at once and stays on a swipe', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = .macOS;
    final wentBack = await _swipeGoesBack(tester);
    debugDefaultTargetPlatformOverride = null;

    expect(wentBack, isFalse);
  });

  testWidgets('on Android a page fades in instead of showing at once', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = .android;
    await tester.pumpWidget(_androidApp());
    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final route = ModalRoute.of(tester.element(find.text('Second')))!;
    final midway = route.animation!.status;
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    expect(route, isA<AndroidPageRoute<void>>());
    expect(midway, AnimationStatus.forward);
  });

  testWidgets('on Android the back gesture previews the page behind, and '
      'letting go goes back', (tester) async {
    debugDefaultTargetPlatformOverride = .android;
    await tester.pumpWidget(_androidApp());
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.text('Second')))!;

    await _backGesture(tester, 'startBackGesture', 0);
    await tester.pump();
    await _backGesture(tester, 'updateBackGestureProgress', 0.5);
    await tester.pump();
    final previewing = route.popGestureInProgress;
    final behindShows = find.text('First').evaluate().isNotEmpty;

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    expect(previewing, isTrue);
    expect(behindShows, isTrue);
    expect(find.text('Second'), findsNothing);
  });
}
