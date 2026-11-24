import 'dart:convert';
import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// The family the harness registers the real font under.
const screenFontFamily = 'ScreenSans';

/// flutter_test draws text whose style has no font family with its built-in
/// box font, and a font loaded with [FontLoader] can't replace that default.
/// Ferret's theme leaves the family empty (the system font), so this loads a
/// real font under [screenFontFamily] and [applyScreenFont] points every
/// label at it right before a capture.
///
/// Font used, first one found:
/// 1. `/System/Library/Fonts/SFNS.ttf`: San Francisco, what macOS draws
///    Ferret with. A variable font; weights come from its `wght` axis.
/// 2. Arial (Regular + Bold) from `/System/Library/Fonts/Supplemental`.
/// 3. DejaVu Sans on Linux.
/// 4. Segoe UI, then Arial, from the Windows Fonts folder.
///
/// Icon fonts (Lucide) come from the app's font manifest.
Future<void> loadScreenFonts() async {
  final loader = FontLoader(screenFontFamily);
  if (_firstExisting(_variableCandidates) case final variable?) {
    loader.addFont(_read(variable));
    _usesWeightAxis = true;
  }

  if (!_usesWeightAxis) {
    final regular = _firstExisting(_regularCandidates);
    if (regular == null) {
      throw StateError('No font found for screenshots.');
    }

    loader.addFont(_read(regular));
    if (_firstExisting(_boldCandidates) case final bold?) {
      loader.addFont(_read(bold));
    }
  }

  await loader.load();
  MiddleEllipsisText.debugMeasureFontFamily = screenFontFamily;

  if (_firstExisting(_symbolCandidates) case final symbols?) {
    await (FontLoader(_symbolFamily)..addFont(_read(symbols))).load();
  }

  await _loadManifestFonts();
}

var _usesWeightAxis = false;
final _iconFamilies = <String>{};

/// Points every text and text field under [root] at [screenFontFamily]. Call
/// it after the last build and before capturing: a rebuild puts the
/// original styles back. Returns how many labels it changed, so the caller
/// can lay out again and catch list items built during that layout.
int applyScreenFont(RenderObject root) {
  var changed = 0;
  void visit(RenderObject node) {
    if (node is RenderParagraph && !_isPatched(node.text)) {
      node.text = _withFont(node.text);
      changed++;
    }

    if (node is RenderEditable) {
      if (node.text case final text? when !_isPatched(text)) {
        node.text = _withFont(text);
        changed++;
      }
    }

    node.visitChildren(visit);
  }

  visit(root);
  return changed;
}

bool _isPatched(InlineSpan span) => switch (span) {
  TextSpan(:final style?) =>
    style.fontFamily == screenFontFamily ||
        _iconFamilies.any((style.fontFamily ?? '').endsWith),
  TextSpan(style: null, :final children?) => children.every(_isPatched),
  _ => true,
};

InlineSpan _withFont(InlineSpan span) {
  if (span is! TextSpan) {
    return span;
  }

  return TextSpan(
    text: span.text,
    style: _styled(span.style),
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    semanticsLabel: span.semanticsLabel,
    locale: span.locale,
    spellOut: span.spellOut,
    children: span.children?.map(_withFont).toList(),
  );
}

TextStyle? _styled(TextStyle? style) {
  if (style == null) {
    return null;
  }

  final family = style.fontFamily ?? '';
  final isIcon = _iconFamilies.any(family.endsWith);
  if (isIcon) {
    return style;
  }

  final weight = style.fontWeight ?? FontWeight.normal;
  return style.copyWith(
    fontFamily: screenFontFamily,
    fontFamilyFallback: const [_symbolFamily],
    fontVariations: switch (_usesWeightAxis) {
      true => [FontVariation.weight(weight.value.toDouble())],
      false => style.fontVariations,
    },
  );
}

Future<void> _loadManifestFonts() async {
  final String manifest;
  try {
    manifest = await rootBundle.loadString('FontManifest.json');
  } on Object {
    return;
  }

  final families = jsonDecode(manifest) as List<Object?>;
  for (final family in families.whereType<Map<String, Object?>>()) {
    final name = family['family'];
    final fonts = family['fonts'];
    if (name is! String || fonts is! List<Object?>) {
      continue;
    }

    _iconFamilies.add(name.split('/').last);
    final loader = FontLoader(name);
    for (final font in fonts.whereType<Map<String, Object?>>()) {
      if (font['asset'] case final String asset) {
        loader.addFont(rootBundle.load(asset));
      }
    }

    await loader.load();
  }
}

Future<ByteData> _read(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.sublistView(bytes);
}

String? _firstExisting(List<String> paths) {
  for (final path in paths) {
    if (File(path).existsSync()) {
      return path;
    }
  }

  return null;
}

/// Arrows and symbols San Francisco lacks, such as the menubar's ⇆.
const _symbolFamily = 'ScreenSymbols';

final _symbolCandidates = [
  '/System/Library/Fonts/Apple Symbols.ttf',
  '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
  _windowsFont('seguisym.ttf'),
];

const _variableCandidates = ['/System/Library/Fonts/SFNS.ttf'];

final _regularCandidates = [
  '/System/Library/Fonts/Supplemental/Arial.ttf',
  '/Library/Fonts/Arial.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
  _windowsFont('segoeui.ttf'),
  _windowsFont('arial.ttf'),
];

final _boldCandidates = [
  '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  '/Library/Fonts/Arial Bold.ttf',
  '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf',
  _windowsFont('segoeuib.ttf'),
  _windowsFont('arialbd.ttf'),
];

/// [name] in the Windows Fonts folder, which honours a Windows installed
/// on another drive.
String _windowsFont(String name) => [
  Platform.environment['WINDIR'] ?? r'C:\Windows',
  'Fonts',
  name,
].join(r'\');
