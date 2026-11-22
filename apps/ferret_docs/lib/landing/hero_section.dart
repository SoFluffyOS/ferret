import 'dart:convert';

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
          Component.text(
            'Free and open source · No account · Encrypted',
          ),
        ]),
        const h1(id: 'hero-title', [Component.text(LandingContent.pitch)]),
        const p(classes: 'lead', [Component.text(LandingContent.subPitch)]),
        const p(classes: 'acronym', [Component.text(LandingContent.acronym)]),
        const div(classes: 'actions', [
          a(
            id: 'hero-download',
            classes: 'button primary',
            href: '#download',
            [Component.text('Download')],
          ),
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
              li([
                Marker(platform.icon),
                Component.text(platform.name),
                if (platform.download == null && platform.command == null)
                  const span(classes: 'later', [Component.text(' · not yet')]),
              ]),
          ],
        ),
        script(content: _forThisSystem),
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

/// Turns **Download** into **Download for Mac** (or Android) with the file
/// itself, when the browser says it runs there. Anything else, and with no
/// script, it stays a jump to the cards. An iPad asks for the Mac page, so a
/// touch screen on "Macintosh" counts as iPhone.
final _forThisSystem = () {
  final files = {
    for (final platform in LandingContent.platforms)
      if (platform.download case final download?)
        platform.name: [download, 'Download for ${platform.name}'],
  };
  return '(function(){'
      'var f=${jsonEncode(files)},u=navigator.userAgent,'
      'b=document.getElementById("hero-download"),'
      'k=/Android/.test(u)?"Android"'
      ':/iPhone|iPad|iPod/.test(u)||navigator.maxTouchPoints>1&&/Macintosh/.test(u)?"iPhone"'
      ':/Macintosh/.test(u)?"Mac":/Windows/.test(u)?"Windows"'
      ':/Linux|X11/.test(u)?"Linux":"";'
      'if(b&&f[k]){b.href=f[k][0];b.textContent=f[k][1];}'
      '})();';
}();
