import 'package:ferret_docs/landing/landing.dart';
import 'package:jaspr/dom.dart' as dom;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// The docs layout with Ferret's icons in the head: the favicon, the home
/// screen icon, the page's canonical address and the picture a link preview
/// shows.
class FerretDocsLayout extends DocsLayout {
  const FerretDocsLayout({super.sidebar, super.header, super.footer});

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield dom.link(rel: 'canonical', href: '${SiteLinks.origin}${page.url}');
    yield dom.meta(
      attributes: {'property': 'og:url'},
      content: '${SiteLinks.origin}${page.url}',
    );
    yield const dom.link(rel: 'stylesheet', href: '/docs.css');
    yield const dom.link(
      rel: 'icon',
      type: 'image/svg+xml',
      href: '/images/logo.svg',
    );
    yield const dom.link(
      rel: 'icon',
      href: '/favicon.ico',
      attributes: {'sizes': '48x48'},
    );
    yield const dom.link(
      rel: 'apple-touch-icon',
      href: '/images/apple-touch-icon.png',
    );
    yield const dom.meta(
      attributes: {'property': 'og:image'},
      content: '${SiteLinks.origin}/images/social.png',
    );
    yield const dom.meta(
      attributes: {'property': 'og:image:width'},
      content: '1200',
    );
    yield const dom.meta(
      attributes: {'property': 'og:image:height'},
      content: '630',
    );
    yield const dom.meta(name: 'twitter:card', content: 'summary_large_image');
    yield const dom.meta(name: 'theme-color', content: '#2B2320');
  }
}
