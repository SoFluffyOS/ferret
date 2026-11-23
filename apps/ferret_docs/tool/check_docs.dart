import 'dart:io';

import 'package:path/path.dart' as p;

import 'gen_proto_reference.dart' as reference;

/// Checks docs before a build: every relative link and image points at
/// a file that exists, and the protocol reference matches proto/. Exits
/// with 1 when something is wrong.
Future<void> main(List<String> args) async {
  final repo = p.normalize(p.join(Directory.current.path, '..', '..'));
  final public = p.join(repo, 'docs');
  final problems = <String>[];

  final pages = Directory(public)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .toList();

  final link = RegExp(r'!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)');
  for (final page in pages) {
    final relative = p.relative(page.path, from: public);
    final text = page.readAsStringSync();
    for (final match in link.allMatches(text)) {
      final target = match.group(1) ?? '';
      final problem = _checkTarget(target, page, public);
      if (problem != null) {
        problems.add('$relative: $problem ($target)');
      }
    }
  }

  final assets = Link(p.join(repo, 'apps', 'ferret_docs', 'web', 'assets'));
  if (!assets.existsSync() || !Directory(assets.path).existsSync()) {
    problems.add('apps/ferret_docs/web/assets must link to docs/assets');
  }

  final llms = File(p.join(repo, 'apps', 'ferret_docs', 'web', 'llms.txt'));
  final site = RegExp(r'\]\(https://ferret\.sofluffy\.io/docs([^)#]*)\)');
  for (final match in site.allMatches(llms.readAsStringSync())) {
    final path = match.group(1) ?? '';
    final page = path.isEmpty ? 'index' : path.substring(1);
    if (!File(p.join(public, '$page.md')).existsSync() &&
        !File(p.join(public, page, 'index.md')).existsSync()) {
      problems.add('apps/ferret_docs/web/llms.txt: missing page (/docs$path)');
    }
  }

  final expected = reference.render(p.join(repo, 'proto'));
  final saved = File(p.join(public, 'spec', 'reference.md'));
  if (!saved.existsSync() || saved.readAsStringSync() != expected) {
    problems.add(
      'spec/reference.md is out of date: run scripts/docs.sh reference',
    );
  }

  if (problems.isEmpty) {
    stdout.writeln('Docs OK: ${pages.length} pages.');
    return;
  }

  for (final problem in problems) {
    stderr.writeln(problem);
  }

  exitCode = 1;
}

String? _checkTarget(String target, File page, String public) {
  if (target.contains('://') ||
      target.startsWith('mailto:') ||
      target.startsWith('#')) {
    return null;
  }

  if (target.startsWith('/')) {
    return 'use a relative link so it works on GitHub too';
  }

  final path = target.split('#').first;
  if (path.isEmpty) {
    return null;
  }

  final resolved = p.normalize(p.join(p.dirname(page.path), path));
  if (!p.isWithin(public, resolved)) {
    return 'links outside docs, which is never published';
  }

  if (!File(resolved).existsSync() && !Directory(resolved).existsSync()) {
    return 'missing';
  }

  return null;
}
