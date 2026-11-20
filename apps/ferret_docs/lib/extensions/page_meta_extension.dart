import 'package:jaspr_content/jaspr_content.dart';

/// Gives every docs page a title, a description and a language, read from
/// the Markdown itself: the first `#` heading and the first paragraph after
/// it. A link pasted in a chat or on Hacker News then shows "Clipboard ·
/// Ferret docs" and a line about it, not a bare address. Front matter, when
/// a page has it, wins.
class PageMetaExtension implements PageExtension {
  const PageMetaExtension();

  static const siteName = 'Ferret docs';
  static const _maxDescription = 160;
  static const _skipped = ['F.E.R.R.E.T.', 'Generated from'];

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final heading = _first(nodes, 'h1');
    final paragraph = _firstParagraph(nodes);
    final pageData = page.data.page;
    final headingText = _clean(heading?.innerText ?? '');

    page.apply(
      data: {
        'page': {
          'lang': 'en',
          if (pageData['title'] == null) 'title': titleFor(headingText),
          if (pageData['description'] == null && paragraph != null)
            'description': describe(paragraph.innerText),
        },
      },
    );
    return nodes;
  }

  /// "Clipboard" becomes "Clipboard · Ferret docs"; the docs home, whose
  /// heading is just "Ferret", becomes "Ferret docs".
  static String titleFor(String heading) {
    if (heading.isEmpty || heading == 'Ferret') {
      return siteName;
    }
    return '$heading · $siteName';
  }

  /// One line for a link preview, cut at a word near 160 characters.
  static String describe(String text) {
    final line = _clean(text);
    if (line.length <= _maxDescription) {
      return line;
    }
    final cut = line.substring(0, _maxDescription);
    final space = cut.lastIndexOf(' ');
    return '${cut.substring(0, space > 0 ? space : cut.length)}…';
  }

  /// The first top-level paragraph that says what the page is about. The
  /// docs home opens with the F.E.R.R.E.T. acronym line and the generated
  /// protocol reference with a note for maintainers; neither describes the
  /// page, so both are skipped.
  static ElementNode? _firstParagraph(List<Node> nodes) {
    for (final node in nodes) {
      if (node is ElementNode &&
          node.tag == 'p' &&
          !_skipped.any(node.innerText.startsWith)) {
        return node;
      }
    }
    return null;
  }

  /// The first [tag] at the top level of the page, so a TL;DR quote or a
  /// list item never stands in for the page's own first paragraph.
  static ElementNode? _first(List<Node> nodes, String tag) {
    for (final node in nodes) {
      if (node is ElementNode && node.tag == tag) {
        return node;
      }
    }
    return null;
  }

  static String _clean(String text) => text
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
