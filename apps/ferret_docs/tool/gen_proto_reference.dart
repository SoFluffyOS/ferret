import 'dart:io';

import 'package:path/path.dart' as p;

/// Writes docs/public/spec/reference.md from the .proto files, so the
/// protocol reference can never drift from the source.
void main() {
  final repo = p.normalize(p.join(Directory.current.path, '..', '..'));
  final output = File(p.join(repo, 'docs', 'public', 'spec', 'reference.md'));
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(render(p.join(repo, 'proto')));
  stdout.writeln('Wrote ${p.relative(output.path, from: repo)}');
}

String render(String protoRoot) {
  final files =
      Directory(p.join(protoRoot, 'ferret'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.proto'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final out = StringBuffer()
    ..writeln('# Protocol reference')
    ..writeln()
    ..writeln(
      'Generated from `proto/` by `scripts/docs.sh reference`. Do not edit by hand.',
    )
    ..writeln()
    ..writeln(
      'Every message travels inside an `Envelope` (see `ferret.v1`), whose `feature` field names the feature and whose `type` field is the full message name below.',
    );

  String? package;
  for (final file in files) {
    final parsed = _parse(file.readAsLinesSync());
    if (parsed.package != package) {
      package = parsed.package;
      out
        ..writeln()
        ..writeln('## `$package`');
    }

    for (final type in parsed.types) {
      out
        ..writeln()
        ..writeln('### ${type.kind} `${type.name}`')
        ..writeln();
      if (type.comment.isNotEmpty) {
        out
          ..writeln(type.comment)
          ..writeln();
      }

      if (type.entries.isEmpty) {
        continue;
      }

      final isEnum = type.kind == 'enum';
      out
        ..writeln(switch (isEnum) {
          true => '| Value | Number | Meaning |',
          false => '| Field | Type | Number | Meaning |',
        })
        ..writeln(switch (isEnum) {
          true => '|---|---|---|',
          false => '|---|---|---|---|',
        });
      for (final entry in type.entries) {
        final meaning = entry.comment.replaceAll('|', r'\|');
        out.writeln(switch (isEnum) {
          true => '| `${entry.name}` | ${entry.number} | $meaning |',
          false =>
            '| `${entry.name}` | `${entry.type}` | ${entry.number} | $meaning |',
        });
      }
    }
  }

  return out.toString();
}

class _Entry {
  _Entry(this.name, this.type, this.number, this.comment);

  final String name;
  final String type;
  final String number;
  final String comment;
}

class _Type {
  _Type(this.kind, this.name, this.comment);

  final String kind;
  final String name;
  final String comment;
  final List<_Entry> entries = [];
}

({String package, List<_Type> types}) _parse(List<String> lines) {
  var package = '';
  final types = <_Type>[];
  final stack = <_Type>[];
  final comment = <String>[];
  final field = RegExp(
    r'^(repeated\s+|optional\s+)?([\w.<>, ]+?)\s+(\w+)\s*=\s*(\d+)',
  );
  final value = RegExp(r'^(\w+)\s*=\s*(\d+)');
  final declaration = RegExp(r'^(message|enum)\s+(\w+)');

  for (final raw in lines) {
    final line = raw.trim();
    if (line.startsWith('//')) {
      comment.add(line.substring(2).trim());
      continue;
    }

    if (line.startsWith('package ')) {
      package = line.substring('package '.length).replaceAll(';', '').trim();
      comment.clear();
      continue;
    }

    if (declaration.firstMatch(line) case final match?) {
      final parent = stack.lastOrNull;
      final name = switch (parent) {
        final parent? => '${parent.name}.${match.group(2)}',
        null => match.group(2) ?? '',
      };
      final type = _Type(match.group(1) ?? '', name, comment.join(' '));
      types.add(type);
      stack.add(type);
      comment.clear();
      continue;
    }

    if (line.startsWith('}')) {
      if (stack.isNotEmpty) {
        stack.removeLast();
      }

      comment.clear();
      continue;
    }

    final current = stack.lastOrNull;
    if (current == null) {
      comment.clear();
      continue;
    }

    final trailing = switch (line.indexOf('//')) {
      -1 => '',
      final index => line.substring(index + 2).trim(),
    };
    final note = [...comment, if (trailing.isNotEmpty) trailing].join(' ');

    comment.clear();
    if (current.kind == 'enum') {
      if (value.firstMatch(line) case final match?) {
        current.entries.add(
          _Entry(match.group(1) ?? '', '', match.group(2) ?? '', note),
        );
      }

      continue;
    }

    if (field.firstMatch(line) case final match?) {
      final modifier = match.group(1)?.trim() ?? '';
      final type = [
        if (modifier.isNotEmpty) modifier,
        match.group(2)?.trim() ?? '',
      ].join(' ');
      current.entries.add(
        _Entry(match.group(3) ?? '', type, match.group(4) ?? '', note),
      );
    }
  }

  return (package: package, types: types);
}
