import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:ferret_docs/landing/themed_shot.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What Ferret is in five seconds: the ferret, the pitch, where to get it and
/// which devices it runs on, then the app itself.
class HeroSection extends StatelessComponent {
  const HeroSection();

  @override
  Component build(BuildContext context) => section(
    classes: 'hero',
    attributes: {'aria-labelledby': 'hero-title'},
    [
      div(classes: 'wrap hero-text', [
        const img(
          classes: 'hero-logo',
          src: SiteLinks.logo,
          alt: 'The Ferret icon: a cream ferret popping up on a dark plate',
          width: 112,
          height: 112,
        ),
        const p(classes: 'eyebrow', [
          Component.text('Free and open source · No account · No cloud'),
        ]),
        const h1(id: 'hero-title', [Component.text(LandingContent.pitch)]),
        const p(classes: 'lead', [Component.text(LandingContent.subPitch)]),
        const div(classes: 'actions', [
          a(classes: 'button primary', href: '#download', [
            Component.text('Download'),
          ]),
          a(classes: 'button', href: SiteLinks.docs, [
            Component.text('Docs'),
          ]),
          a(classes: 'button', href: SiteLinks.github, [
            Component.text('GitHub'),
          ]),
        ]),
        ul(
          classes: 'badges',
          attributes: {'aria-label': 'Runs on'},
          [
            for (final platform in LandingContent.platforms)
              li([Marker(platform.emoji), Component.text(platform.name)]),
          ],
        ),
      ]),
      const div(classes: 'wrap hero-shot', [
        ThemedShot(
          name: 'window-overview',
          alt:
              'The Ferret window on a Mac: a Pixel 9’s overview with a call, '
              'a song and a file on the way',
          width: 1400,
          height: 1008,
          eager: true,
          classes: 'shot shot-window shot-hero',
        ),
      ]),
    ],
  );
}
