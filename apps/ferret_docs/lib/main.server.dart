/// Ferret's site: the landing page at `/`, and `docs` pre-rendered
/// under `/docs`.
library;

import 'package:ferret_docs/content/docs_loader.dart';
import 'package:ferret_docs/content/plain_grammar.dart';
import 'package:ferret_docs/extensions/markdown_links_extension.dart';
import 'package:ferret_docs/extensions/page_meta_extension.dart';
import 'package:ferret_docs/landing/landing.dart';
import 'package:ferret_docs/layouts/ferret_docs_layout.dart';
import 'package:ferret_docs/main.server.options.dart';
import 'package:ferret_docs/navigation/docs_sidebar.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/components/header.dart';
import 'package:jaspr_content/components/image.dart';
import 'package:jaspr_content/components/theme_toggle.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The docs live in the repository's `docs`; nothing is copied.
const docsRoot = '../../docs';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    ContentApp.custom(
      loaders: [DocsLoader(docsRoot)],
      configResolver: PageConfig.all(
        parsers: const [MarkdownParser()],
        extensions: [
          const MarkdownLinksExtension(),
          const PageMetaExtension(),
          HeadingAnchorsExtension(),
          const TableOfContentsExtension(),
        ],
        components: [
          Callout(),
          CodeBlock(
            defaultLanguage: 'text',
            grammars: {
              for (final language in plainLanguages) language: plainGrammar,
            },
          ),
          const Image(zoom: true),
        ],
        layouts: [
          FerretDocsLayout(
            header: const Header(
              title: 'Ferret',
              logo: SiteLinks.logo,
              items: [
                a(classes: 'docs-nav-link', href: '/', [
                  Component.text('Home'),
                ]),
                a(classes: 'docs-nav-link', href: SiteLinks.docs, [
                  Component.text('Docs'),
                ]),
                a(classes: 'docs-nav-link', href: SiteLinks.github, [
                  Component.text('GitHub'),
                ]),
                ThemeToggle(),
              ],
            ),
            sidebar: docsSidebar(docsRoot),
          ),
        ],
        theme: ContentTheme(
          primary: const ThemeColor(Color('#B4651A'), dark: Color('#F0AE52')),
          background: ThemeColor(
            ThemeColors.stone.$50,
            dark: ThemeColors.stone.$950,
          ),
          colors: [ContentColors.quoteBorders.apply(const Color('#E39A33'))],
        ),
      ),
      routerBuilder: (routes) => Router(
        routes: [
          Route(path: '/', builder: (_, _) => const LandingPage()),
          Route(path: '/404.html', builder: (_, _) => const NotFoundPage()),
          for (final loaderRoutes in routes) ...loaderRoutes,
        ],
      ),
    ),
  );
}
