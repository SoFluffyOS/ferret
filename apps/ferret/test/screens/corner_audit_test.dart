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
//
// Touch screens (touch_…: the Android build on a phone and on a tablet
// held both ways, the iPhone build on an iPhone) have no window corner:
// the screen is the window. There every dialog is measured against its
// own corner (Corners.dialog; DIALOG-RADIUS otherwise), and what sits at
// its edge nests in it (DIALOG-…), a button exactly concentric because the
// dialog's corner follows its buttons. A shape in a corner of the physical
// screen is a capsule with at least 16 of margin (SCREEN-SHAPE,
// SCREEN-MARGIN), as Apple asks on phones: no app knows the device's own
// corner. Only these, with --plain-name "touch_".
//
// Desktop dialogs (desk_…: in the Mac popover and in the window on a
// Mac, Windows and Linux) are measured the same way against their own
// corner (Corners.dialog on that platform), and so is every dialog a
// popover or window screen opens. Only these, with --plain-name "desk_".
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/protocol.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/remote_input.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'screens_test.dart' show Screen, appFeatures, phoneFeatures, screens;
import 'shelf_screens_test.dart' show fillShelf, shelfViewModel;
import 'support/ios_features.dart';
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
      // A button without a radius takes the design system's 12.
      final r = (widget as Button).radius ?? 12;
      if (r > concentric + 0.5 && r > 12.5) {
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

/// What a button draws: its fill, which can be narrower than the box
/// it is given (a button sized to its label starts at the box's left).
Rect? _fillOf(Element button) {
  Rect? fill;
  void visit(Element child) {
    if (fill != null) return;
    if (child.widget case DecoratedBox(decoration: ShapeDecoration())) {
      fill = _rectOf(child);
      return;
    }
    child.visitChildren(visit);
  }

  button.visitChildren(visit);
  return fill ?? _rectOf(button);
}

List<_Shape> _shapesIn(Rect window, {Element? root}) {
  final shapes = <_Shape>[];
  final seen = <RenderObject>{};
  void visit(Element element) {
    final radius = _visibleRadius(element.widget);
    if (radius != null) {
      final rect = switch (element.widget) {
        Button() => _fillOf(element),
        _ => _rectOf(element),
      };
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

  switch (root) {
    case final root?:
      visit(root);
    case null:
      WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }
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
  (String, double, double) corner, {
  bool strict = false,
}) {
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
  // Buttons keep the design system's 12 at the least, as in a card. In a
  // container Ferret draws itself, such as a dialog, the container follows
  // its buttons instead, so there a button is exactly concentric.
  final concentric = switch ((strict, shape.element.widget)) {
    (true, Button()) => Corners.inner(outerRadius, inset),
    _ => Corners.concentric(
      outerRadius,
      inset,
      minimum: switch (shape.element.widget) {
        Button() => 12,
        _ => null,
      },
    ),
  };
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

bool _scrolls(Element element, {required bool strict}) {
  if (!strict) {
    return element.findAncestorWidgetOfExactType<Scrollable>() != null;
  }
  final position = Scrollable.maybeOf(element)?.position;
  return position != null &&
      position.hasContentDimensions &&
      position.maxScrollExtent > 0.5;
}

/// Measures every shape in a corner of [window] against its corner, then
/// every shape in a corner of one of those against that shape, and on in.
void _auditWindow(
  String label,
  Rect window,
  double windowRadius, {
  Element? root,
  String kind = 'WINDOW',
  String where = 'the window',
  bool strict = false,
}) {
  final shapes = _shapesIn(window, root: root);
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
    // What scrolls only passes the corner; the list clips it there. In a
    // dialog, a list that fits stays put, so it counts.
    if (_scrolls(shape.element, strict: strict)) continue;
    for (final corner in _cornersOf(window, shape.rect)) {
      atWindow.add(shape);
      _checkCorner(
        kind,
        label,
        shape,
        where,
        windowRadius,
        corner,
        strict: strict,
      );
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
          strict: strict,
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

  _touchMain();
  _desktopMain();

  for (final screen in screens) {
    for (final size in [popover]) {
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
          _auditDialogs('${screen.name} ${size.name}');
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
  _auditDialogs(label);
  _auditWindow(
    label,
    Offset.zero & Size(size.width, size.height),
    Corners.window,
  );
  await rig.dispose(tester);
}

/// Phones, an iPhone and an Android tablet held both ways: the screen is
/// the window, and what Ferret draws over it (dialogs, the display bar)
/// is a container of its own.
const _touchSizes = [phone, iphone, tabletPortrait, tabletLandscape];

bool _onTablet(CaptureSize size) => size.name.startsWith('tablet');

/// Screens whose script only works on a phone: it taps the one ••• a
/// phone shows, and a tablet shows two.
const _phoneScripts = {'home_menu'};

/// Every dialog on screen, measured against its own corner: the dialog is
/// the outermost shape in a popup route (`showGeneralDialog`). On touch
/// screens its corner is [Corners.dialog] (DIALOG-RADIUS otherwise), and
/// a shape at its edge nests in it (DIALOG-…); a button there is exactly
/// concentric, because the dialog's corner follows its buttons.
void _auditDialogs(String label) {
  final all = _shapesIn(Offset.zero & const Size(1e5, 1e5));
  final inPopup = <Element, _Shape>{
    for (final shape in all)
      if (ModalRoute.of(shape.element) is PopupRoute) shape.element: shape,
  };
  for (final shape in inPopup.values) {
    var nested = false;
    shape.element.visitAncestorElements((ancestor) {
      if (inPopup.containsKey(ancestor)) {
        nested = true;
        return false;
      }
      return true;
    });
    if (nested) continue;
    final size =
        '${shape.rect.width.toStringAsFixed(0)}x'
        '${shape.rect.height.toStringAsFixed(0)}';
    if ((shape.radius - Corners.dialog).abs() > 0.5) {
      _findings.add(
        'DIALOG-RADIUS $label · ${shape.name} ($size): '
        'r=${shape.radius.toStringAsFixed(1)}, a dialog is '
        '${Corners.dialog.toStringAsFixed(0)}',
      );
    }
    _auditWindow(
      label,
      shape.rect,
      shape.radius,
      root: shape.element,
      kind: 'DIALOG',
      where: 'the dialog r=${shape.radius.toStringAsFixed(0)}',
      strict: true,
    );
  }
}

/// Anything in a corner of the physical screen, off the screen's edges:
/// Apple's guidance for phones is a capsule with extra margin there, as
/// no app knows the device's own corner (WWDC25 "Get to know the new
/// design system"). Full-bleed shapes (0 from both edges) are clipped by
/// the screen and left out. SCREEN-SHAPE: not a capsule. SCREEN-MARGIN:
/// nearer than 16 to either edge.
void _auditScreen(String label, CaptureSize size) {
  final screen = Offset.zero & Size(size.width, size.height);
  for (final shape in _shapesIn(screen)) {
    if (shape.rect.width >= screen.width - 1 &&
        shape.rect.height >= screen.height - 1) {
      continue;
    }
    if (shape.element.findAncestorWidgetOfExactType<Scrollable>() != null) {
      continue;
    }
    if (ModalRoute.of(shape.element) is PopupRoute) continue;
    for (final (name, side, end) in _cornersOf(screen, shape.rect)) {
      if (side < 0.5 && end < 0.5) continue;
      final rect = shape.rect;
      final capsule = rect.shortestSide / 2;
      final where =
          '${shape.name} (${rect.width.toStringAsFixed(0)}x'
          '${rect.height.toStringAsFixed(0)}) at the $name of the screen: '
          'side ${side.toStringAsFixed(1)} end ${end.toStringAsFixed(1)}';
      if (shape.radius < capsule - 0.5) {
        _findings.add(
          'SCREEN-SHAPE $label · $where, r=${shape.radius.toStringAsFixed(1)}'
          ' (a capsule is ${capsule.toStringAsFixed(1)})',
        );
      }
      if (side < 15.5 || end < 15.5) {
        _findings.add('SCREEN-MARGIN $label · $where');
      }
    }
  }
}

/// Builds the app as [size]'s device builds it: the Android build on a
/// phone or a tablet, the iPhone build on an iPhone.
Future<ScreenRig> _touchRig(
  WidgetTester tester,
  CaptureSize size, {
  bool tipsDone = true,
  bool sampleActivity = false,
}) => ScreenRig.create(
  tester,
  features: [
    ...switch (size == iphone) {
      true => iosFeatures(),
      false => phoneFeatures(),
    },
    if (sampleActivity) SampleActivityFeatureUi(),
  ],
  tipsDone: tipsDone,
  asPhone: size == phone,
  asIphone: size == iphone,
  asTablet: _onTablet(size),
);

void _measureTouch(WidgetTester tester, String label, CaptureSize size) {
  _audit(tester, label);
  _auditDialogs(label);
  _auditScreen(label, size);
}

typedef _TouchScene = Future<void> Function(WidgetTester tester, ScreenRig rig);

BuildContext _homeContext(ScreenRig rig) {
  final context = rig.navigator?.context;
  if (context == null) throw StateError('No navigator.');
  return context;
}

/// The dialogs Ferret draws, on any screen.
final _dialogScenes = <String, _TouchScene>{
  'dialog_confirm': (tester, rig) async {
    unawaited(
      FerretConfirmDialog.show(
        _homeContext(rig),
        title: 'Shut down MacBook Air?',
        message:
            'It counts down 10 seconds first, and anyone at MacBook Air '
            'can cancel.',
        negativeText: 'Cancel',
        positiveText: 'Shut down',
      ),
    );
  },
  'dialog_text': (tester, rig) async {
    unawaited(
      FerretTextDialog.show(
        _homeContext(rig),
        title: 'Rename this phone',
        labelText: 'Name',
        cancelText: 'Cancel',
        confirmText: 'Rename',
        initialValue: 'Pixel 9',
      ),
    );
  },
  'dialog_content': (tester, rig) async {
    unawaited(
      FerretContentDialog.show(
        _homeContext(rig),
        title: 'How notifications get here',
        content: 'Pixel 9 sends its notifications while Ferret runs on it.',
        neutralText: 'OK',
      ),
    );
  },
  'dialog_pairing': (tester, rig) async {
    unawaited(
      PairingPromptDialog.show(
        _homeContext(rig),
        PairingPrompt(
          device: DeviceInfo(
            id: 'abcdabcdabcdabcd',
            name: 'MacBook Air',
            platform: .PLATFORM_MACOS,
            formFactor: .FORM_FACTOR_LAPTOP,
          ),
          code: '123456',
          expiresAt: DateTime.now().add(const Duration(minutes: 1)),
        ),
      ),
    );
  },
};

/// The dialogs Ferret draws on a phone or a tablet, and the bar over a
/// computer's display on one.
final _touchScenes = <String, _TouchScene>{
  ..._dialogScenes,
  // As the display's stage places it: under the status bar (24 on
  // Android, 59 on an iPhone with a Dynamic Island).
  'display_bar': (tester, rig) => rig.open(
    tester,
    Stack(
      children: [
        Positioned(
          top: switch (defaultTargetPlatform) {
            .iOS => 59,
            _ => 24,
          },
          left: 0,
          right: 0,
          child: DisplayBar(
            shown: true,
            onLeave: () {},
            title: "MacBook Pro's display",
            hint: 'Tap the handle at the top to show this bar.',
            stopLabel: 'Stop',
            onStop: () {},
          ),
        ),
      ],
    ),
  ),
};

void _touchMain() {
  for (final screen in screens) {
    for (final size in _touchSizes) {
      if (size == iphone && !screen.onIphone) continue;
      if (screen.only case final only? when only != size) continue;
      if (_onTablet(size) && _phoneScripts.contains(screen.name)) continue;
      final label = 'touch_${screen.name} ${size.name}';
      testWidgets(label, (tester) async {
        await _onScreen(tester, size, () async {
          final rig = await _touchRig(
            tester,
            size,
            tipsDone: screen.tipsDone,
            sampleActivity: screen.sampleActivity,
          );
          await rig.show(tester);
          await screen.script(tester, rig);
          await rig.settle(tester);
          _measureTouch(tester, label, size);
          await rig.dispose(tester);
        });
      });
    }
  }

  for (final MapEntry(key: name, value: scene) in _touchScenes.entries) {
    for (final size in _touchSizes) {
      final label = 'touch_$name ${size.name}';
      testWidgets(label, (tester) async {
        await _onScreen(tester, size, () async {
          // Measured in light mode, and rendered in both to crop the
          // corners from. A dialog takes the theme it opened in.
          for (final brightness in Brightness.values) {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            final rig = await _touchRig(tester, size);
            await rig.show(tester);
            await scene(tester, rig);
            await rig.settle(tester);
            if (brightness == .light) _measureTouch(tester, label, size);
            await rig.capture(tester, 'touch_$name', size, brightness);
            await rig.dispose(tester);
          }
        });
      });
    }
  }
}

/// The Mac popover, and the window on a Mac, Windows and Linux.
const _desktopSizes = [
  popover,
  _window,
  CaptureSize('window', 1000, 720, platform: .windows),
  CaptureSize('window', 1000, 720, platform: .linux),
];

/// What a computer adds to the dialogs every screen has: a button with
/// the keyboard's focus, and a consent dialog with its buttons stacked.
final _desktopScenes = <String, _TouchScene>{
  ..._dialogScenes,
  // Tab to the first button: one focus ring, on it.
  'dialog_focus': (tester, rig) async {
    await _dialogScenes['dialog_confirm']!(tester, rig);
    await rig.settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  },
  'dialog_consent': (tester, rig) async {
    unawaited(
      rig.navigator?.push(
        RawDialogRoute<void>(
          barrierDismissible: true,
          barrierColor: FluffyColors.barrier,
          pageBuilder: (_, _, _) => ConsentDialog(
            request: ConsentRequest(
              deviceId: 'abcdabcdabcdabcd',
              deviceName: 'Pixel 9',
              askedAt: DateTime(2026, 11, 21, 9),
            ),
            onAnswer: (_) {},
          ),
        ),
      ),
    );
  },
};

String _desktopPrefix(CaptureSize size) => switch (size.platform) {
  .windows => 'windows_',
  .linux => 'linux_',
  _ => '',
};

void _desktopMain() {
  for (final MapEntry(key: name, value: scene) in _desktopScenes.entries) {
    for (final size in _desktopSizes) {
      final shot = 'desk_${_desktopPrefix(size)}$name';
      final label = '$shot ${size.name}';
      testWidgets(label, (tester) async {
        await _onScreen(tester, size, () async {
          for (final brightness in Brightness.values) {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            final rig = await ScreenRig.create(
              tester,
              features: appFeatures(),
              tipsDone: true,
            );
            await rig.show(tester);
            await scene(tester, rig);
            await rig.settle(tester);
            // A focused button grows a little and draws its ring outside,
            // so it is rendered, not measured.
            if (brightness == .light && name != 'dialog_focus') {
              _audit(tester, label);
              _auditDialogs(label);
            }
            await rig.capture(tester, shot, size, brightness);
            await rig.dispose(tester);
          }
        });
      });
    }
  }
}
