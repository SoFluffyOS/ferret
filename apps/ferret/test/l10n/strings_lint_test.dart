// Keeps Ferret ready for translation: no English typed straight into a
// widget, and every translation file in step with English.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _repo = Directory('../..');

/// Text a person reads, passed as a literal where a string from the ARB
/// belongs.
final _userFacing = RegExp(
  r'''(?:\bText\(\s*|\b(?:label|tooltip|semanticsLabel|title|subtitle|body|hintText|placeholder|reason|help|message|value):\s*)(['"])((?:(?!\1).)*)\1''',
);

/// A literal that holds a word: two letters in a row outside `${…}`.
final _word = RegExp(r'\p{L}{2,}', unicode: true);

/// Literals that are not words to translate, by file. Keep it short.
const _allowed = {
  // The language picker names each language in itself.
  'modules/shell/lib/services/language_preference.dart': {
    'English',
    'Tiếng Việt',
  },
  // A key combination, the same in every language.
  'modules/shell/lib/services/global_shortcut.dart': {'⌃⌥Space'},
  // Names of other products.
  'modules/drop/lib/services/quickshare/quickshare_ids.dart': {'Quick Share'},
  // English fallbacks for tests; the app passes translated texts.
  'modules/find/lib/models/ring_texts.dart': {
    'Ferret is ringing',
    r'$requesterName is looking for this device.',
    'Found it',
  },
  'modules/mirroring/lib/feature/mirroring_feature.dart': {
    r'$deviceName wants to see this screen',
    'Tap to answer',
    'Screen sharing requests',
    r'Sharing screen with $deviceName',
    'Everything on this screen is visible there',
    'Stop',
    'Screen sharing',
  },
  // The app's name in the window list and the task switcher.
  'modules/shell/lib/app/app_view.dart': {'Ferret'},
};

List<File> _dartSources() => [
  for (final root in ['modules', 'packages/feature_kit/lib'])
    for (final entity in Directory('${_repo.path}/$root').listSync(
      recursive: true,
    ))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          entity.path.contains('/lib/') &&
          !entity.path.contains('/generated/') &&
          !entity.path.contains('/test/'))
        entity,
];

String _relative(File file) => file.absolute.path
    .replaceFirst('${_repo.absolute.path}/', '')
    .replaceAll(
      RegExp(r'^(\./)+'),
      '',
    );

Map<String, Object?> _arb(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();

Set<String> _placeholders(Map<String, Object?> arb, String key) =>
    switch (arb['@$key']) {
      {'placeholders': final Map<Object?, Object?> placeholders} => {
        for (final name in placeholders.keys) '$name',
      },
      _ => const {},
    };

void main() {
  test('widgets show strings from the ARB files, never typed English', () {
    final found = <String>[];
    for (final file in _dartSources()) {
      final path = _relative(file)
          .replaceFirst(RegExp(r'^.*?(?=modules/|packages/)'), '');
      final allowed = _allowed[path] ?? const <String>{};
      for (final (index, line) in file.readAsLinesSync().indexed) {
        if (line.trimLeft().startsWith('//')) {
          continue;
        }

        for (final match in _userFacing.allMatches(line)) {
          final literal = match.group(2) ?? '';
          final words = literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
          if (!_word.hasMatch(words) || allowed.contains(literal)) {
            continue;
          }

          found.add('$path:${index + 1}: "$literal"');
        }
      }
    }

    expect(
      found,
      isEmpty,
      reason:
          'Put these in the module ARB (lib/l10n/arb/<module>_en.arb) and use '
          'context.<module>L10n, or add them to _allowed with a reason.',
    );
  });

  test('every translation has the same keys and placeholders as English', () {
    final problems = <String>[];
    for (final module in Directory('${_repo.path}/modules').listSync()) {
      final folder = Directory('${module.path}/lib/l10n/arb');
      if (!folder.existsSync()) {
        continue;
      }

      final files = folder.listSync().whereType<File>().toList();
      final english = files.where((file) => file.path.endsWith('_en.arb'));
      if (english.isEmpty) {
        continue;
      }

      final template = _arb(english.first);
      for (final file in files) {
        if (file.path.endsWith('_en.arb') || !file.path.endsWith('.arb')) {
          continue;
        }

        final name = file.uri.pathSegments.last;
        final translated = _arb(file);
        if (!translated.containsKey('@@x-translation')) {
          problems.add(
            '$name: no @@x-translation line saying who translated it',
          );
        }

        for (final MapEntry(:key, :value) in template.entries) {
          if (key.startsWith('@') || value is! String) {
            continue;
          }

          final other = translated[key];
          if (other is! String) {
            problems.add('$name: missing $key');
            continue;
          }

          for (final placeholder in _placeholders(template, key)) {
            final used = value.contains('{$placeholder');
            if (used && !other.contains('{$placeholder')) {
              problems.add('$name: $key lacks {$placeholder}');
            }
          }
        }

        for (final key in translated.keys) {
          if (!key.startsWith('@') && !template.containsKey(key)) {
            problems.add('$name: $key is not in English any more');
          }
        }
      }
    }

    expect(problems, isEmpty);
  });

  test('every ARB message with a count uses a plural', () {
    final problems = <String>[];
    for (final module in Directory('${_repo.path}/modules').listSync()) {
      final folder = Directory('${module.path}/lib/l10n/arb');
      if (!folder.existsSync()) {
        continue;
      }

      for (final file in folder.listSync().whereType<File>()) {
        if (!file.path.endsWith('_en.arb')) {
          continue;
        }

        final arb = _arb(file);
        for (final MapEntry(:key, :value) in arb.entries) {
          if (key.startsWith('@') || value is! String) {
            continue;
          }

          final meta = arb['@$key'];
          if (meta is! Map) {
            continue;
          }

          final placeholders = meta['placeholders'];
          if (placeholders is! Map) {
            continue;
          }

          for (final MapEntry(key: name, value: spec) in placeholders.entries) {
            final counts =
                name == 'count' && spec is Map && spec['type'] == 'int';
            if (counts && !value.contains('{$name, plural,')) {
              problems.add('${file.uri.pathSegments.last}: $key');
            }
          }
        }
      }
    }

    expect(problems, isEmpty, reason: 'Wrap {count} in an ICU plural.');
  });

  test('"this Mac" is spelled inside each sentence, never dropped in', () {
    final problems = <String>[];
    for (final module in Directory('${_repo.path}/modules').listSync()) {
      final folder = Directory('${module.path}/lib/l10n/arb');
      if (!folder.existsSync()) {
        continue;
      }

      for (final file in folder.listSync().whereType<File>()) {
        if (!file.path.endsWith('.arb')) {
          continue;
        }

        for (final MapEntry(:key, :value) in _arb(file).entries) {
          if (value is String && value.contains('{here}')) {
            problems.add('${file.uri.pathSegments.last}: $key');
          }
        }
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'Use {here, select, mac{this Mac} phone{this phone} '
          'tablet{this tablet} other{this computer}}, so a language with '
          'cases can inflect it per sentence.',
    );
  });
}
