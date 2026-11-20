import 'package:ferret_docs/landing/feature_story.dart';
import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One card per platform: the download, or the line to paste, and the
/// install guide.
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
            Marker('download'),
            Component.text('Get Ferret.'),
          ]),
          p([
            Component.text(
              'Free, no account. Pick your system. Every '
              'download is the newest release on ',
            ),
            a(href: SiteLinks.releases, [Component.text('GitHub')]),
            Component.text('.'),
          ]),
        ]),
        ul(classes: 'platforms', [
          for (final platform in LandingContent.platforms)
            li([_card(platform)]),
        ]),
      ]),
    ],
  );

  Component _card(PlatformEntry platform) => div(classes: 'platform reveal', [
    span(classes: 'platform-name', [
      Marker(platform.icon),
      Component.text(platform.name),
    ]),
    span(classes: 'platform-how', [Component.text(platform.how)]),
    ...switch ((platform.download, platform.command)) {
      (final download?, _) => [
        a(
          classes: 'button primary platform-download',
          href: download,
          [Component.text(platform.downloadLabel ?? 'Download')],
        ),
      ],
      (null, final command?) => [
        pre(classes: 'platform-command', [
          code([Component.text(command)]),
        ]),
      ],
      (null, null) => [
        const span(classes: 'platform-soon', [Component.text('Not yet')]),
      ],
    },
    a(classes: 'platform-go', href: platform.guide, [
      const Component.text('Install guide →'),
    ]),
  ]);
}
