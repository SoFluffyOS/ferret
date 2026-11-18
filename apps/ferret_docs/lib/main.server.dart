/// Ferret's docs site. Pre-renders `docs/public` into static pages.
library;

import 'package:ferret_docs/extensions/markdown_links_extension.dart';
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

/// The docs live in the repository's `docs/public`; nothing is copied.
const docsRoot = '../../docs/public';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    ContentApp(
      directory: docsRoot,
      parsers: const [MarkdownParser()],
      extensions: [
        const MarkdownLinksExtension(),
        HeadingAnchorsExtension(),
        const TableOfContentsExtension(),
      ],
      components: [Callout(), CodeBlock(), const Image(zoom: true)],
      layouts: [
        DocsLayout(
          header: const Header(
            title: 'Ferret',
            logo: '/images/logo.svg',
            items: [ThemeToggle()],
          ),
          sidebar: docsSidebar(docsRoot),
        ),
      ],
      theme: ContentTheme(
        primary: const ThemeColor(
          Color('#E8833A'),
          dark: Color('#F2A766'),
        ),
        background: ThemeColor(
          ThemeColors.stone.$50,
          dark: ThemeColors.stone.$950,
        ),
        colors: [ContentColors.quoteBorders.apply(const Color('#E8833A'))],
      ),
    ),
  );
}
