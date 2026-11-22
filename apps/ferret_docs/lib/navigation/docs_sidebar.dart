import 'dart:io';

import 'package:jaspr_content/components/sidebar.dart';
import 'package:path/path.dart' as p;

/// Builds the sidebar from the folders in `docs`, so a new page shows
/// up without editing a list. Each folder is a group; each page's title is
/// its first `# ` heading. Pages can set `order: 3` in front matter. Every
/// link starts with [base], where the docs are served.
Sidebar docsSidebar(String root, {String base = '/docs'}) {
  final directory = Directory(root);
  final topLevel = _pages(
    directory,
    root,
    base,
  ).where((link) => link.href != base);
  final groups = <SidebarGroup>[
    SidebarGroup(
      links: [
        SidebarLink(text: 'Overview', href: base),
        ...topLevel,
      ],
    ),
  ];

  final folders =
      directory
          .listSync()
          .whereType<Directory>()
          .where((folder) => !_hidden(folder.path))
          .toList()
        ..sort((a, b) => _groupRank(a.path).compareTo(_groupRank(b.path)));

  for (final folder in folders) {
    final pages = _pages(folder, root, base);
    if (pages.isEmpty) {
      continue;
    }

    groups.add(
      SidebarGroup(title: _groupTitle(p.basename(folder.path)), links: pages),
    );
  }

  return Sidebar(groups: groups);
}

const _groupOrder = [
  'getting-started',
  'features',
  'android-modes',
  'iphone',
  'interop',
  'spec',
];

int _groupRank(String path) {
  final index = _groupOrder.indexOf(p.basename(path));
  return switch (index) {
    -1 => _groupOrder.length,
    _ => index,
  };
}

List<SidebarLink> _pages(Directory folder, String root, String base) {
  final files = folder
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.md') && !_hidden(file.path))
      .toList();
  final entries =
      [
        for (final file in files) (file: file, meta: _meta(file)),
      ]..sort((a, b) {
        final byOrder = a.meta.order.compareTo(b.meta.order);
        if (byOrder != 0) {
          return byOrder;
        }

        return a.meta.title.compareTo(b.meta.title);
      });

  return [
    for (final entry in entries)
      SidebarLink(
        text: entry.meta.title,
        href: p.posix.join(
          base,
          _route(p.relative(entry.file.path, from: root)),
        ),
      ),
  ];
}

({String title, int order}) _meta(File file) {
  final lines = file.readAsLinesSync();
  var order = 1000;
  var title = _titleCase(p.basenameWithoutExtension(file.path));

  for (final line in lines) {
    final orderMatch = RegExp(r'^order:\s*(\d+)').firstMatch(line);
    if (orderMatch != null) {
      order = int.parse(orderMatch.group(1) ?? '1000');
    }

    if (line.startsWith('# ')) {
      title = line.substring(2).trim();
      break;
    }
  }

  return (title: title, order: order);
}

String _route(String relativePath) {
  final withoutExtension = relativePath
      .substring(0, relativePath.length - '.md'.length)
      .replaceAll(r'\', '/');
  return switch (withoutExtension) {
    'index' => '',
    final path when path.endsWith('/index') => path.substring(
      0,
      path.length - '/index'.length,
    ),
    final path => path,
  };
}

bool _hidden(String path) {
  final name = p.basename(path);
  return name.startsWith('_') || name.startsWith('.') || name == 'assets';
}

/// A group's name in the sidebar, in words a newcomer knows: "Other apps"
/// is what Settings calls LocalSend and Quick Share.
String _groupTitle(String folder) => switch (folder) {
  'getting-started' => 'Getting started',
  'android-modes' => 'Android modes',
  'interop' => 'Other apps',
  'spec' => 'Protocol and security',
  _ => _titleCase(folder),
};

String _titleCase(String slug) => slug
    .split('-')
    .map(
      (word) => switch (word) {
        'iphone' => 'iPhone',
        '' => '',
        _ => '${word[0].toUpperCase()}${word.substring(1)}',
      },
    )
    .join(' ');
