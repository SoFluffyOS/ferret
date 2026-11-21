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
//
// The Mac popover is a window with its own corner (Corners.popover, drawn
// by macOS): on popover screens, and on the shelf in the popover and in
// its floating panel, every visible shape in a corner of that window is
// measured against it. WINDOW-UNEVEN: its gaps to the two edges that meet
// at the corner differ. WINDOW-ROUND / WINDOW-SQUARE: its radius is not
// concentric with the window's at that gap (Corners.concentric). The same
// goes one level in, and further, for every shape in a corner of one of
// those (NESTED-…), such as the tiles in the shelf box. Shapes in a list
// that scrolls are left out at the window: they only pass its corner.
//
// A desktop window has its own corner too (Corners.window: 16 on a Mac,
// 8 on Windows, 12 on Linux, drawn by the system): every window screen,
// at each window size and on Windows and Linux, is measured against it
// the same way.
@Tags(['screens'])
library;

import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'screens_test.dart' show Screen, appFeatures, phoneFeatures, screens;
import 'shelf_screens_test.dart' show fillShelf, shelfViewModel;
import 'support/sample_activity.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';
import 'window_screens_test.dart' show WindowScreen, windowScreens, windowSizes;

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

/// A shape this far or nearer to both edges at a corner sits in it.
const _cornerReach = 24.0;

typedef _Shape = ({Element element, Rect rect, double radius, String name});

double? _cornerOf(BorderRadiusGeometry radius) {
  final resolved = radius.resolve(TextDirection.ltr);
  return [
    resolved.topLeft.x,
    resolved.topRight.x,
    resolved.bottomLeft.x,
    resolved.bottomRight.x,
  ].reduce((a, b) => a > b ? a : b);
}

bool _drawsSide(ShapeBorder shape) => switch (shape) {
  OutlinedBorder(:final side) => side.style != BorderStyle.none,
  _ => false,
};

/// The corner of what [widget] draws, when it draws a rounded shape that
/// can be seen: a filled or outlined decoration, a dashed outline or a
/// button.
double? _visibleRadius(Widget widget) {
  switch (widget) {
    case DecoratedBox(:final ShapeDecoration decoration):
      final shows =
          decoration.color != null ||
          decoration.gradient != null ||
          decoration.image != null ||
          _drawsSide(decoration.shape);
      if (!shows) return null;
      return switch (decoration.shape) {
        RoundedSuperellipseBorder(:final borderRadius) ||
        RoundedRectangleBorder(:final borderRadius) => _cornerOf(borderRadius),
        _ => null,
      };
    case DecoratedBox(:final BoxDecoration decoration):
      final shows =
          decoration.color != null ||
          decoration.gradient != null ||
          decoration.image != null ||
          decoration.border != null;
      if (!shows || decoration.shape == BoxShape.circle) return null;
      return switch (decoration.borderRadius) {
        final radius? => _cornerOf(radius),
        null => 0,
      };
    case DashedOutline(:final radius):
      return radius;
    case RoundCard(:final borderRadius):
      return borderRadius;
    case Button(:final radius):
      return radius ?? 12;
  }
  return null;
}

String _shapeName(Element element) {
  final widget = element.widget;
  var owner = '';
  element.visitAncestorElements((ancestor) {
    final type = ancestor.widget.runtimeType.toString();
    if (type.startsWith('_') ||
        type.startsWith('Shelf') ||
        type.contains('Card') ||
        type.contains('Tile') ||
        type.contains('Frame')) {
      owner = type;
      return false;
    }
    return true;
  });
  return switch (widget) {
    Button(:final label, :final tooltip) =>
      'Button "${label ?? tooltip ?? _textIn(element)}"',
    _ => '${widget.runtimeType} in $owner',
  };
}

List<_Shape> _shapesIn(Rect window) {
  final shapes = <_Shape>[];
  final seen = <RenderObject>{};
  void visit(Element element) {
    final radius = _visibleRadius(element.widget);
    if (radius != null) {
      final rect = _rectOf(element);
      final render = element.renderObject;
      if (rect != null &&
          render != null &&
          seen.add(render) &&
          rect.width >= 24 &&
          rect.height >= 24 &&
          window.inflate(1).contains(rect.topLeft) &&
          window.inflate(1).contains(rect.bottomRight)) {
        shapes.add((
          element: element,
          rect: rect,
          radius: radius,
          name: _shapeName(element),
        ));
      }
    }
    // A button is one shape: the fill it draws inside is its own corner.
    if (element.widget is Button) return;
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return shapes;
}

/// The gaps from [inner] to the two edges of [outer] at each corner it
/// sits in.
Iterable<(String, double, double)> _cornersOf(Rect outer, Rect inner) sync* {
  final left = inner.left - outer.left;
  final right = outer.right - inner.right;
  final top = inner.top - outer.top;
  final bottom = outer.bottom - inner.bottom;
  for (final (name, side, end) in [
    ('top-left', left, top),
    ('top-right', right, top),
    ('bottom-left', left, bottom),
    ('bottom-right', right, bottom),
  ]) {
    if (side < -0.5 || end < -0.5) continue;
    if (side <= _cornerReach && end <= _cornerReach) {
      yield (name, side, end);
    }
  }
}

void _checkCorner(
  String kind,
  String label,
  _Shape shape,
  String where,
  double outerRadius,
  (String, double, double) corner,
) {
  final (name, side, end) = corner;
  final size =
      '${shape.rect.width.toStringAsFixed(0)}x'
      '${shape.rect.height.toStringAsFixed(0)}';
  if ((side - end).abs() > 1.5) {
    _findings.add(
      '$kind-UNEVEN $label · ${shape.name} ($size) at the $name of $where: '
      'side ${side.toStringAsFixed(1)} end ${end.toStringAsFixed(1)}',
    );
  }
  final inset = side < end ? side : end;
  // Buttons keep the design system's 12 at the least, as in a card.
  final concentric = Corners.concentric(
    outerRadius,
    inset,
    minimum: switch (shape.element.widget) {
      Button() => 12,
      _ => null,
    },
  );
  final verdict = switch (shape.radius - concentric) {
    > 0.5 => 'ROUND',
    < -0.5 => 'SQUARE',
    _ => null,
  };
  if (verdict == null) return;
  _findings.add(
    '$kind-$verdict $label · ${shape.name} ($size) at the $name of $where '
    'r=${outerRadius.toStringAsFixed(0)}, inset ${inset.toStringAsFixed(1)}: '
    'r=${shape.radius.toStringAsFixed(1)}, concentric '
    '${concentric.toStringAsFixed(1)}',
  );
}

/// Measures every shape in a corner of [window] against its corner, then
/// every shape in a corner of one of those against that shape, and on in.
void _auditWindow(String label, Rect window, double windowRadius) {
  final shapes = _shapesIn(window);
  final byElement = {for (final shape in shapes) shape.element: shape};
  _Shape? parentOf(_Shape shape) {
    _Shape? parent;
    shape.element.visitAncestorElements((ancestor) {
      final found = byElement[ancestor];
      if (found != null && found.rect != shape.rect) {
        parent = found;
        return false;
      }
      return true;
    });
    return parent;
  }

  final atWindow = <_Shape>{};
  for (final shape in shapes) {
    if (shape.rect.width >= window.width - 1 &&
        shape.rect.height >= window.height - 1) {
      continue;
    }
    // What scrolls only passes the corner; the list clips it there.
    if (shape.element.findAncestorWidgetOfExactType<Scrollable>() != null) {
      continue;
    }
    for (final corner in _cornersOf(window, shape.rect)) {
      atWindow.add(shape);
      _checkCorner('WINDOW', label, shape, 'the window', windowRadius, corner);
    }
  }

  final checked = {...atWindow};
  var level = atWindow;
  while (level.isNotEmpty) {
    final next = <_Shape>{};
    for (final shape in shapes) {
      if (checked.contains(shape)) continue;
      final parent = parentOf(shape);
      if (parent == null || !level.contains(parent)) continue;
      for (final corner in _cornersOf(parent.rect, shape.rect)) {
        next.add(shape);
        _checkCorner(
          'NESTED',
          label,
          shape,
          '${parent.name} r=${parent.radius.toStringAsFixed(0)}',
          parent.radius,
          corner,
        );
      }
    }
    checked.addAll(next);
    level = next;
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

typedef _ShelfScript = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  ShelfStore store,
);

/// The shelf at the popover's bottom edge and in its floating panel, in
/// each of its looks.
final _shelfScreens = <String, _ShelfScript>{
  'empty': (tester, rig, store) async {},
  'empty_drop_over': (tester, rig, store) async =>
      shelfViewModel(tester).hover(over: true),
  'items': (tester, rig, store) => fillShelf(tester, store),
  'drop_over': (tester, rig, store) async {
    await fillShelf(tester, store);
    await rig.settle(tester);
    shelfViewModel(tester).hover(over: true);
  },
  'selection': (tester, rig, store) async {
    await fillShelf(tester, store);
    await rig.settle(tester);
    final viewModel = shelfViewModel(tester);
    viewModel.select(viewModel.items.first.id);
  },
  'hidden': (tester, rig, store) => fillShelf(tester, store),
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });
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
          if (size == popover) {
            _auditWindow(
              '${screen.name} ${size.name}',
              Offset.zero & const Size(380, 560),
              Corners.popover,
            );
          }
          await rig.dispose(tester);
        });
      });
    }
  }

  for (final MapEntry(key: name, value: script) in _shelfScreens.entries) {
    for (final inPanel in [false, true]) {
      final label = switch (inPanel) {
        true => 'shelf_panel_$name',
        false => 'shelf_$name popover',
      };
      testWidgets(label, (tester) async {
        await _onScreen(tester, popover, () async {
          final shelf = ShelfFeatureUi(
            showsPreviewsFrom: (_) => name != 'hidden',
          );
          final rig = await ScreenRig.create(
            tester,
            features: [...appFeatures(), shelf],
            tipsDone: true,
          );
          await rig.show(tester);
          final store = shelf.feature.store;
          if (store == null) {
            throw StateError('The shelf has no store.');
          }
          await script(tester, rig, store);
          await rig.settle(tester);
          if (!inPanel) {
            _auditWindow(
              label,
              Offset.zero & const Size(380, 560),
              Corners.popover,
            );
          }
          if (inPanel) {
            final viewModel = shelfViewModel(tester);
            await rig.open(
              tester,
              Center(
                child: SizedBox.fromSize(
                  key: const ValueKey('panel'),
                  size: ShelfPanelFrame.size,
                  child: ChangeNotifierProvider.value(
                    value: viewModel,
                    child: ShelfPanelFrame(onOpenList: () {}, onHover: (_) {}),
                  ),
                ),
              ),
            );
            await rig.settle(tester);
            _auditWindow(
              label,
              tester.getRect(find.byKey(const ValueKey('panel'))),
              ShelfPanelFrame.radius,
            );
          }
          await rig.dispose(tester);
        });
      });
    }
  }

  for (final screen in windowScreens) {
    for (final size in windowSizes) {
      final label = 'window_${screen.name} ${size.name}';
      testWidgets(label, (tester) async {
        await _onScreen(
          tester,
          size,
          () => _windowScreen(tester, screen, label, size),
        );
      });
    }
  }

  // Windows and Linux round their windows less than a Mac does.
  for (final screen in windowScreens.where(
    (screen) => _onWindows.contains(screen.name),
  )) {
    for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
      final size = CaptureSize(
        _window.name,
        _window.width,
        _window.height,
        platform: platform,
      );
      final label = '${platform.name}_${screen.name} ${size.name}';
      testWidgets(label, (tester) async {
        await _onScreen(
          tester,
          size,
          () => _windowScreen(tester, screen, label, size),
        );
      });
    }
  }
}

const _onWindows = {'overview', 'device_menu', 'settings', 'activity'};

/// Shows [screen] in the window and measures its corners: buttons in
/// cards, and every shape at the window's edge against [Corners.window].
Future<void> _windowScreen(
  WidgetTester tester,
  WindowScreen screen,
  String label,
  CaptureSize size,
) async {
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
  _audit(tester, label);
  _auditWindow(
    label,
    Offset.zero & Size(size.width, size.height),
    Corners.window,
  );
  await rig.dispose(tester);
}
