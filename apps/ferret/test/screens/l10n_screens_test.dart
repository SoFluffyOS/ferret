// Persona #9, someone who doesn't read English: key screens in Vietnamese,
// in a pseudo-locale (accented, 40% longer, every string in brackets) and in
// that pseudo-locale laid out right to left. Renders into temp/screens as
// `l10n_<variant>_<screen>_<size>_light.png` and writes
// `temp/screens/l10n_report.txt`: text shown without brackets (typed in
// code, or data such as device names), strings glued from pieces, and rows
// that overflow. Run from apps/ferret:
//
//   dart run tool/pseudo_l10n.dart    # after an ARB change
//   flutter test test/screens/l10n_screens_test.dart
@Tags(['screens'])
library;

import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/date_symbol_data_local.dart';

import 'screens_test.dart' show Screen, appFeatures, phoneFeatures, screens;
import 'support/pseudo_l10n.g.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

enum _Variant { vi, pseudo, rtl }

const _names = {
  'home_connected',
  'home_offline',
  'home_activity',
  'device_connected',
  'device_access',
  'settings',
  'settings_advanced',
  'doctor_network',
  'pair',
  'phone_device_connected',
  'phone_settings',
};

/// Words that are data, not strings: device names, addresses, numbers.
final _data = RegExp(
  r'^(Pixel \d+|MacBook Air|iPhone|Galaxy S24|[\d\s:.,·%×/+-]+|[A-Z0-9]{4}( [A-Z0-9]{4})*|Ferret)$',
);

final _report = <String>{};

const _reportNote =
    'Health lines and summaries are built outside widgets with the chosen '
    'language (AppLocale), not the pseudo strings, so English ones show as '
    '"not translated" here; check them in the vi renders. A [phrase] inside '
    'a [sentence] is a name such as "this Mac" put into another string.';

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File('${screensDirectory.path}/l10n_report.txt').writeAsString(
      switch (_report.isEmpty) {
        true => 'Nothing found.\n',
        false => '$_reportNote\n\n${(_report.toList()..sort()).join('\n')}\n',
      },
    );
  });

  for (final variant in _Variant.values) {
    for (final screen in screens.where((each) => _names.contains(each.name))) {
      final size = switch (screen.phone) {
        true => phone,
        false => popover,
      };
      testWidgets('${variant.name} ${screen.name}', (tester) async {
        setScreen(tester, size, .light);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = size.platform;
        final reportError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) {
            _report.add('overflow: ${variant.name} ${screen.name}');
            return;
          }

          reportError?.call(details);
        };
        _use(variant);
        try {
          await _run(tester, screen, size, variant);
        } finally {
          FlutterError.onError = reportError;
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
          AppLocale.chosen.value = null;
          AppLocale.debugLeadingDelegates = const [];
        }
      });
    }
  }
}

void _use(_Variant variant) {
  switch (variant) {
    case .vi:
      AppLocale.chosen.value = const Locale('vi');
    case .pseudo:
      AppLocale.debugLeadingDelegates = pseudoDelegates();
    case .rtl:
      AppLocale.debugLeadingDelegates = [
        const _RtlDelegate(),
        ...pseudoDelegates(),
      ];
  }
}

Future<void> _run(
  WidgetTester tester,
  Screen screen,
  CaptureSize size,
  _Variant variant,
) async {
  final rig = await ScreenRig.create(
    tester,
    features: switch (screen.phone) {
      true => phoneFeatures(),
      false => appFeatures(),
    },
    tipsDone: screen.tipsDone,
    asPhone: screen.phone,
  );
  await rig.show(tester);
  await screen.script(tester, rig);

  final name = 'l10n_${variant.name}_${screen.name}';
  await rig.capture(tester, name, size, .light);
  if (variant == .pseudo) {
    _collect(tester, screen.name);
  }

  for (final overflow in capturedOverflows) {
    if (overflow.startsWith(name)) {
      _report.add('overflow: $overflow');
    }
  }

  await rig.dispose(tester);
}

/// Lines on screen that aren't one whole translated string.
void _collect(WidgetTester tester, String screen) {
  final root = tester.binding.rootElement?.renderObject;
  if (root == null) {
    return;
  }

  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      final text = node.text.toPlainText().trim();
      var outside = text;
      for (var depth = 0; depth < 3; depth++) {
        outside = outside.replaceAll(RegExp(r'\[[^\[\]]*\]'), '');
      }
      outside = outside.replaceAll(RegExp(r'[\s·•:,.()–—|/]+'), ' ').trim();
      final pieces = RegExp(r'\[').allMatches(text).length;
      if (outside.isNotEmpty &&
          RegExp(r'\p{L}{2,}', unicode: true).hasMatch(outside) &&
          !_data.hasMatch(outside)) {
        _report.add('not translated: $screen: "$text"');
      }

      if (pieces > 1 && !text.contains(' · ')) {
        _report.add('glued: $screen: "$text"');
      }
    }

    node.visitChildren(visit);
  }

  visit(root);
}

/// Lays every view out right to left, as Arabic or Hebrew would.
class _RtlDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _RtlDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const _RtlWidgetsLocalizations());

  @override
  bool shouldReload(_RtlDelegate old) => false;
}

class _RtlWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _RtlWidgetsLocalizations();

  @override
  TextDirection get textDirection => .rtl;
}
