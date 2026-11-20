import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Links in three columns, then who makes Ferret.
class SiteFooter extends StatelessComponent {
  const SiteFooter();

  @override
  Component build(BuildContext context) => footer(classes: 'footer', [
    div(classes: 'wrap footer-inner', [
      const div(classes: 'footer-brand', [
        img(src: SiteLinks.logo, alt: '', width: 40, height: 40),
        p([
          strong([Component.text('Ferret')]),
          br(),
          Component.text('Your devices, together. On your Wi-Fi.'),
        ]),
      ]),
      _column('Ferret', [
        ('Download', '/#download'),
        ('Docs', SiteLinks.docs),
        ('Privacy', SiteLinks.privacy),
        ('FAQ', '/#faq'),
      ]),
      _column('Open source', [
        ('GitHub', SiteLinks.github),
        ('License: GPL-3.0', SiteLinks.license),
        ('Protocol spec', '/docs/spec/reference'),
        ('Sponsor', SiteLinks.sponsor),
      ]),
      _column('SoFluffy', [
        ('ferret.sofluffy.io', SiteLinks.origin),
        ('sofluffy.io', 'https://sofluffy.io'),
      ]),
    ]),
    const div(classes: 'wrap footer-bottom', [
      p([Component.text('© 2026 SoFluffy · Made by Simon')]),
      a(href: '#top', [Component.text('Back to top ↑')]),
    ]),
  ]);

  Component _column(String title, List<(String, String)> links) => nav(
    classes: 'footer-column',
    attributes: {'aria-label': title},
    [
      h2([Component.text(title)]),
      ul([
        for (final (label, href) in links)
          li([
            a(href: href, [Component.text(label)]),
          ]),
      ]),
    ],
  );
}
