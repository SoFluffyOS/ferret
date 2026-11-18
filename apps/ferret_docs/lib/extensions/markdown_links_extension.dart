import 'package:jaspr_content/jaspr_content.dart';
import 'package:path/path.dart' as p;

/// Turns the relative `.md` links that read well on GitHub into site routes,
/// and relative asset paths into `/assets/...`, while the page renders. The
/// Markdown files stay the only copy.
class MarkdownLinksExtension implements PageExtension {
  const MarkdownLinksExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async => [
    for (final node in nodes) _rewrite(node, page.path),
  ];

  Node _rewrite(Node node, String pagePath) {
    if (node is! ElementNode) {
      return node;
    }

    final attributes = {...node.attributes};
    if (attributes['href'] case final href? when node.tag == 'a') {
      attributes['href'] = routeFor(href, pagePath);
    }

    if (attributes['src'] case final source? when node.tag == 'img') {
      attributes['src'] = assetFor(source, pagePath);
    }

    return ElementNode(node.tag, attributes, [
      for (final child in node.children ?? const <Node>[])
        _rewrite(child, pagePath),
    ]);
  }

  /// `../features/clipboard.md#limits` on `getting-started/android.md`
  /// becomes `/features/clipboard#limits`.
  static String routeFor(String href, String pagePath) {
    if (_isExternal(href)) {
      return href;
    }

    final (target, fragment) = _splitFragment(href);
    if (!target.endsWith('.md')) {
      return href;
    }

    final resolved = p.posix.normalize(
      p.posix.join(p.posix.dirname(pagePath), target),
    );
    final withoutExtension = resolved.substring(
      0,
      resolved.length - '.md'.length,
    );
    final route = switch (withoutExtension) {
      'index' => '/',
      final path when path.endsWith('/index') =>
        '/${path.substring(0, path.length - '/index'.length)}',
      final path => '/$path',
    };
    return '$route$fragment';
  }

  /// `../assets/pairing.png` becomes `/assets/pairing.png`.
  static String assetFor(String source, String pagePath) {
    if (_isExternal(source)) {
      return source;
    }

    final resolved = p.posix.normalize(
      p.posix.join(p.posix.dirname(pagePath), source),
    );
    return '/$resolved';
  }

  static bool _isExternal(String href) =>
      href.startsWith('/') ||
      href.startsWith('#') ||
      href.contains('://') ||
      href.startsWith('mailto:');

  static (String, String) _splitFragment(String href) {
    final hash = href.indexOf('#');
    if (hash < 0) {
      return (href, '');
    }

    return (href.substring(0, hash), href.substring(hash));
  }
}
