// Accessibility audit: walks the same screens as `screens_test.dart` and
// `window_screens_test.dart` with semantics on and writes what it finds to
// `temp/screens/a11y/`. Run from apps/ferret:
//
//   flutter test test/screens/a11y_audit_test.dart
//
// - `guidelines.txt`: tap target size, unlabeled tap targets and text
//   contrast, per screen.
// - `large_text.txt` and `xl_<name>_<size>_light.png`: every screen at 200%
//   text, with the rows that overflow.
// - `keyboard.txt` and `focus_<name>.png`: what Tab reaches in the popover
//   and the window, in order, against what a pointer can tap.
//
// Findings are written down, not failed on: the regression tests that must
// stay green live next to the widgets they cover.
@Tags(['screens'])
library;

import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show Screen, appFeatures, phoneFeatures, screens;
import 'support/sample_activity.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';
import 'window_screens_test.dart' show WindowScreen, windowScreens;

final _directory = Directory('${screensDirectory.path}/a11y');

/// WCAG 2.2 "Target Size (Minimum)": what a mouse pointer needs on desktop,
/// where the 44 and 48 point touch guidelines don't apply.
const _pointerTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);

const _window = CaptureSize('window', 1000, 720);

final _guidelineFindings = <String>[];
final _largeTextFindings = <String>[];
final _keyboardFindings = <String>[];

List<FeatureUi> _featuresFor(Screen screen) => [
  ...switch (screen.phone) {
    true => phoneFeatures(),
    false => appFeatures(),
  },
  if (screen.sampleActivity) SampleActivityFeatureUi(),
];

/// Runs [body] the way the screenshot tests do: sized, on [size]'s
/// platform, with layout overflows kept out of the test's failures.
Future<void> _onScreen(
  WidgetTester tester,
  CaptureSize size,
  Brightness brightness,
  Future<void> Function() body,
) async {
  setScreen(tester, size, brightness);
  mockPlugins(tester);
  debugDisableShadows = false;
  debugDefaultTargetPlatformOverride = size.platform;
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      return;
    }

    reportError?.call(details);
  };
  final semantics = tester.ensureSemantics();
  try {
    await body();
  } finally {
    semantics.dispose();
    FlutterError.onError = reportError;
    debugDisableShadows = true;
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> _evaluate(
  WidgetTester tester,
  String label,
  Map<String, AccessibilityGuideline> guidelines,
) async {
  for (final MapEntry(key: name, value: guideline) in guidelines.entries) {
    try {
      final evaluation = await guideline.evaluate(tester);
      if (evaluation.passed) {
        continue;
      }

      _guidelineFindings.add('## $label · $name\n${evaluation.reason}\n');
    } on Object catch (error) {
      _guidelineFindings.add('## $label · $name\ncould not evaluate: $error\n');
    }
  }
}

Map<String, AccessibilityGuideline> _guidelinesFor(CaptureSize size) => {
  'tap target': switch (size.platform) {
    .android => androidTapTargetGuideline,
    .iOS => iOSTapTargetGuideline,
    _ => _pointerTapTargetGuideline,
  },
  'label': labeledTapTargetGuideline,
  'contrast': textContrastGuideline,
};

/// Every focusable stop Tab reaches from the top of the screen, as the
/// label a screen reader would speak there.
Future<List<String>> _tabStops(WidgetTester tester, {int limit = 60}) async {
  final stops = <String>[];
  final seen = <FocusNode>{};
  for (var step = 0; step < limit; step++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 120));
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (focus == null || context == null || !seen.add(focus)) {
      break;
    }

    final render = context.findRenderObject();
    stops.add(_spokenAt(render));
  }

  return stops;
}

final _noLetters = RegExp(r'^[^\p{L}]+', unicode: true);

/// Presses Tab until the focused stop's text, icons left out, starts
/// with [text].
Future<void> _tabTo(WidgetTester tester, String text, {int limit = 40}) async {
  for (var step = 0; step < limit; step++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 120));
    final render = FocusManager.instance.primaryFocus?.context
        ?.findRenderObject();
    final spoken = _spokenAt(render).replaceFirst(_noLetters, '');
    if (spoken.startsWith(text)) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
  }

  fail('Tab never reached "$text"');
}

String _spokenAt(RenderObject? render) {
  if (render is! RenderBox || !render.hasSize) {
    return '(nothing drawn)';
  }

  final labels = <String>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      labels.add(node.text.toPlainText());
    }

    node.visitChildren(visit);
  }

  visit(render);
  final size = render.size;
  final text = switch (labels.isEmpty) {
    true => '(no text)',
    false => labels.join(' / '),
  };
  return '$text [${size.width.round()}x${size.height.round()}]';
}

/// Labels of everything a pointer can tap on screen right now.
List<String> _tappable(WidgetTester tester) {
  final found = <String>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final canTap = data.hasAction(SemanticsAction.tap);
    if (canTap && !data.flagsCollection.isHidden) {
      found.add(switch (data.label.isEmpty) {
        true => '(unlabeled ${node.rect.size})',
        false => data.label.replaceAll('\n', ' / '),
      });
    }

    node.visitChildren(visit);
    return true;
  }

  for (final view in tester.binding.renderViews) {
    view.owner?.semanticsOwner?.rootSemanticsNode?.visitChildren(visit);
  }

  return found;
}

Future<void> _write(String name, List<String> lines) async {
  if (lines.isEmpty) {
    return;
  }

  _directory.createSync(recursive: true);
  File('${_directory.path}/$name').writeAsStringSync('${lines.join('\n')}\n');
}

Future<void> _captureTo(
  WidgetTester tester,
  ScreenRig rig,
  String name,
) async {
  final boundary = rig.boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    return;
  }

  for (var pass = 0; pass < 5; pass++) {
    final changed = applyScreenFont(boundary);
    tester.binding.rootPipelineOwner.flushLayout();
    if (changed == 0) {
      break;
    }
  }

  tester.binding.rootPipelineOwner
    ..flushCompositingBits()
    ..flushPaint();
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: capturePixelRatio);
    final bytes = await image.toByteData(format: .png);
    image.dispose();
    if (bytes == null) {
      return;
    }

    await _directory.create(recursive: true);
    await File(
      '${_directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadScreenFonts);
  // Written after every test, so a run of one group or a stopped run
  // still leaves what it found.
  tearDown(() async {
    await _write('guidelines.txt', _guidelineFindings);
    await _write('large_text.txt', _largeTextFindings.toSet().toList());
    await _write('keyboard.txt', _keyboardFindings);
  });

  group('guidelines', () {
    for (final screen in screens) {
      for (final size in [phone, popover]) {
        for (final brightness in Brightness.values) {
          if (brightness == .dark && size != popover) {
            continue;
          }

          final label = '${screen.name} ${size.name} ${brightness.name}';
          testWidgets(label, (tester) async {
            final tall = switch (screen.tall && size != popover) {
              true => CaptureSize(
                size.name,
                size.width,
                screen.fullHeight,
                platform: size.platform,
              ),
              false => size,
            };
            await _onScreen(tester, tall, brightness, () async {
              final rig = await ScreenRig.create(
                tester,
                features: _featuresFor(screen),
                tipsDone: screen.tipsDone,
                asPhone: screen.phone,
              );
              await rig.show(tester);
              await screen.script(tester, rig);
              await rig.settle(tester);
              await _evaluate(tester, label, _guidelinesFor(size));
              await rig.dispose(tester);
            });
          });
        }
      }
    }

    for (final screen in windowScreens) {
      for (final brightness in Brightness.values) {
        final label = 'window_${screen.name} ${brightness.name}';
        testWidgets(label, (tester) async {
          await _onScreen(tester, _window, brightness, () async {
            final rig = await _windowRig(tester, screen);
            await _evaluate(tester, label, _guidelinesFor(_window));
            await rig.dispose(tester);
          });
        });
      }
    }
  });

  group('large text', () {
    for (final screen in screens) {
      for (final size in [phone, popover]) {
        final label = '${screen.name} ${size.name}';
        testWidgets(label, (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _onScreen(tester, size, .light, () async {
            final rig = await ScreenRig.create(
              tester,
              features: _featuresFor(screen),
              tipsDone: screen.tipsDone,
              asPhone: screen.phone,
            );
            await rig.show(tester);
            await screen.script(tester, rig);
            await rig.settle(tester);
            await _captureTo(tester, rig, 'xl_${screen.name}_${size.name}');
            final boundary = rig.boundaryKey.currentContext?.findRenderObject();
            if (boundary != null) {
              for (final labels in overflowingRows(boundary)) {
                _largeTextFindings.add('$label: $labels');
              }
            }

            await rig.dispose(tester);
          });
        });
      }
    }

    for (final screen in windowScreens) {
      final label = 'window_${screen.name}';
      testWidgets(label, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _onScreen(tester, _window, .light, () async {
          final rig = await _windowRig(tester, screen);
          await _captureTo(tester, rig, 'xl_$label');
          final boundary = rig.boundaryKey.currentContext?.findRenderObject();
          if (boundary != null) {
            for (final labels in overflowingRows(boundary)) {
              _largeTextFindings.add('$label: $labels');
            }
          }

          await rig.dispose(tester);
        });
      });
    }
  });

  group('keyboard', () {
    const names = {
      'home_empty',
      'home_connected',
      'home_nearby',
      'home_menu',
      'pair_code',
      'pair_request',
      'pair',
      'device_connected',
      'device_forget',
      'settings',
      'settings_group_general',
      'activity',
    };
    for (final screen in screens) {
      if (!names.contains(screen.name)) {
        continue;
      }

      testWidgets('${screen.name} popover', (tester) async {
        await _onScreen(tester, popover, .light, () async {
          final rig = await ScreenRig.create(
            tester,
            features: _featuresFor(screen),
            tipsDone: screen.tipsDone,
          );
          await rig.show(tester);
          await screen.script(tester, rig);
          await rig.settle(tester);
          await _recordKeyboard(tester, rig, '${screen.name}_popover');
          await rig.dispose(tester);
        });
      });
    }

    // One ring at a time: a button in a card, the card itself, Fix on an
    // offline device and a plain outlined button, focused from the
    // keyboard, on a phone and in the popover.
    const focused = {
      ('home_connected', 'Show screen', 'ghost_in_card'),
      ('home_connected', 'Pixel 9', 'card'),
      ('home_offline', 'Fix', 'fix'),
      ('device_forget', 'Cancel', 'ghost'),
    };
    for (final (screenName, stop, shot) in focused) {
      final screen = screens.firstWhere((each) => each.name == screenName);
      for (final size in [popover, phone]) {
        testWidgets('focus $shot ${size.name}', (tester) async {
          await _onScreen(tester, size, .light, () async {
            final rig = await ScreenRig.create(
              tester,
              features: _featuresFor(screen),
              tipsDone: screen.tipsDone,
              asPhone: size == phone,
            );
            await rig.show(tester);
            await screen.script(tester, rig);
            await rig.settle(tester);
            await _tabTo(tester, stop);
            await _captureTo(tester, rig, 'focus_${shot}_${size.name}');
            await rig.dispose(tester);
          });
        });
      }
    }

    for (final screen in windowScreens) {
      testWidgets('window_${screen.name}', (tester) async {
        await _onScreen(tester, _window, .light, () async {
          final rig = await _windowRig(tester, screen);
          await _recordKeyboard(tester, rig, 'window_${screen.name}');
          await rig.dispose(tester);
        });
      });
    }
  });
}

Future<ScreenRig> _windowRig(WidgetTester tester, WindowScreen screen) async {
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
  return rig;
}

Future<void> _recordKeyboard(
  WidgetTester tester,
  ScreenRig rig,
  String name,
) async {
  final tappable = _tappable(tester);
  final stops = await _tabStops(tester);
  await _captureTo(tester, rig, 'focus_$name');
  _keyboardFindings
    ..add('## $name')
    ..add('tappable (${tappable.length}): ${tappable.join(' | ')}')
    ..add('tab stops (${stops.length}):')
    ..addAll([
      for (final (index, stop) in stops.indexed) '  ${index + 1}. $stop',
    ])
    ..add('');
}
