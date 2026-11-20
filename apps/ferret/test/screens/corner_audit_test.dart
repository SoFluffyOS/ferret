// Corner audit: walks the same screens as `screens_test.dart` and
// `window_screens_test.dart` and writes `temp/screens/a11y/corners.txt`:
// a button or switch in a card's corner whose gaps to the card's side and
// end differ (UNEVEN), and a button rounder than the card's corner allows
// at its inset, above the 12 every control keeps (ROUND). Run from
// apps/ferret:
//
//   fvm flutter test test/screens/corner_audit_test.dart
//
// A switch, or a button beside two lines of text, sits further from the
// card's end than from its side on purpose: the row keeps its height.
@Tags(['screens'])
library;

import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'screens_test.dart' show Screen, appFeatures, phoneFeatures, screens;
import 'support/sample_activity.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';
import 'window_screens_test.dart' show windowScreens;

const _window = CaptureSize('window', 1000, 720);
final _findings = <String>{};

List<FeatureUi> _featuresFor(Screen screen) => [
  ...switch (screen.phone) {
    true => phoneFeatures(),
    false => appFeatures(),
  },
  if (screen.sampleActivity) SampleActivityFeatureUi(),
];

Rect? _rectOf(Element element) {
  final render = element.renderObject;
  if (render is! RenderBox || !render.hasSize || !render.attached) {
    return null;
  }
  return render.localToGlobal(Offset.zero) & render.size;
}

String _textIn(Element element) {
  var text = '(child)';
  void visit(Element child) {
    final widget = child.widget;
    if (widget is Text && text == '(child)') {
      text = widget.data ?? text;
      return;
    }
    child.visitChildren(visit);
  }

  element.visitChildren(visit);
  return text;
}

void _audit(WidgetTester tester, String label) {
  for (final element
      in find
          .byWidgetPredicate((w) => w is Button || w is SwitchToggle)
          .evaluate()) {
    final rect = _rectOf(element);
    if (rect == null || rect.isEmpty) continue;
    Element? card;
    double? cardRadius;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is GroupedCard) {
        card = ancestor;
        cardRadius = Corners.card;
        return false;
      }
      if (widget is RoundCard) {
        card = ancestor;
        cardRadius = widget.borderRadius;
        return false;
      }
      return true;
    });
    final found = card;
    if (found == null) continue;
    final cardRect = _rectOf(found);
    if (cardRect == null) continue;
    final left = rect.left - cardRect.left;
    final right = cardRect.right - rect.right;
    final top = rect.top - cardRect.top;
    final bottom = cardRect.bottom - rect.bottom;
    final h = left < right ? left : right;
    final v = top < bottom ? top : bottom;
    final widget = element.widget;
    final radius = switch (widget) {
      Button(:final radius) => radius?.toStringAsFixed(0) ?? 'default',
      _ => 'switch',
    };
    final name = switch (widget) {
      Button(:final label, :final tooltip, :final semanticLabel) =>
        label ?? tooltip ?? semanticLabel ?? _textIn(element),
      _ => 'switch',
    };
    final where =
        '${found.widget.runtimeType} r=$cardRadius '
        '${cardRect.width.toStringAsFixed(0)}x${cardRect.height.toStringAsFixed(0)}';
    if (h <= 24 && v <= 24 && (h - v).abs() > 1.5) {
      _findings.add(
        'UNEVEN $label · "$name" in $where: side ${h.toStringAsFixed(1)} '
        'end ${v.toStringAsFixed(1)} (button r=$radius, '
        '${rect.width.toStringAsFixed(0)}x${rect.height.toStringAsFixed(0)})',
      );
    }
    final inset = h < v ? h : v;
    if (radius != 'switch' && h <= 24 && v <= 24 && cardRadius != null) {
      final concentric = Corners.inner(cardRadius!, inset);
      final r = (widget as Button).radius;
      if (r == null || r > concentric + 0.5 && r > 12.5) {
        _findings.add(
          'ROUND $label · "$name" in $where at inset '
          '${inset.toStringAsFixed(1)}: button r=$radius, concentric '
          '${concentric.toStringAsFixed(1)}',
        );
      }
    }
  }
}

Future<void> _onScreen(
  WidgetTester tester,
  CaptureSize size,
  Future<void> Function() body,
) async {
  setScreen(tester, size, .light);
  mockPlugins(tester);
  debugDefaultTargetPlatformOverride = size.platform;
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    reportError?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = reportError;
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  setUpAll(loadScreenFonts);
  tearDown(() {
    final out = Directory('${screensDirectory.path}/a11y')
      ..createSync(recursive: true);
    File('${out.path}/corners.txt').writeAsStringSync(
      '${(_findings.toList()..sort()).join('\n')}\n',
    );
  });

  for (final screen in screens) {
    for (final size in [phone, popover]) {
      testWidgets('${screen.name} ${size.name}', (tester) async {
        final tall = switch (screen.tall && size != popover) {
          true => CaptureSize(
            size.name,
            size.width,
            screen.fullHeight,
            platform: size.platform,
          ),
          false => size,
        };
        await _onScreen(tester, tall, () async {
          final rig = await ScreenRig.create(
            tester,
            features: _featuresFor(screen),
            tipsDone: screen.tipsDone,
            asPhone: screen.phone,
          );
          await rig.show(tester);
          await screen.script(tester, rig);
          await rig.settle(tester);
          _audit(tester, '${screen.name} ${size.name}');
          await rig.dispose(tester);
        });
      });
    }
  }

  for (final screen in windowScreens) {
    testWidgets('window_${screen.name}', (tester) async {
      await _onScreen(tester, _window, () async {
        final rig = await ScreenRig.create(
          tester,
          features: [
            ...appFeatures(),
            if (screen.sampleActivity) SampleActivityFeatureUi(),
          ],
          tipsDone: true,
        );
        await rig.show(tester);
        await screen.script(tester, rig);
        await rig.settle(tester);
        _audit(tester, 'window_${screen.name}');
        await rig.dispose(tester);
      });
    });
  }
}
