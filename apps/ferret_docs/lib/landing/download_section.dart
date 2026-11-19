import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One card per platform, each leading to its install guide.
class DownloadSection extends StatelessComponent {
  const DownloadSection();

  @override
  Component build(BuildContext context) => section(
    id: 'download',
    classes: 'download',
    attributes: {'aria-labelledby': 'download-title'},
    [
      div(classes: 'wrap', [
        const div(classes: 'section-head', [
          h2(id: 'download-title', [
            Marker('📦'),
            Component.text('Get Ferret.'),
          ]),
          p([
            Component.text('Binaries come with the first release on '),
            a(href: SiteLinks.releases, [Component.text('GitHub')]),
            Component.text(
              '. Until then, each guide shows how to build it from source.',
            ),
          ]),
        ]),
        ul(classes: 'platforms', [
          for (final platform in LandingContent.platforms)
            li([
              a(classes: 'platform reveal', href: platform.guide, [
                span(classes: 'platform-name', [
                  Marker(platform.emoji),
                  Component.text(platform.name),
                ]),
                span(classes: 'platform-how', [Component.text(platform.how)]),
                const span(classes: 'platform-go', [
                  Component.text('Install guide →'),
                ]),
              ]),
            ]),
        ]),
      ]),
    ],
  );
}
