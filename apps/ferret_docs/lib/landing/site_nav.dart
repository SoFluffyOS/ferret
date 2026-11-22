import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The bar at the top of the landing: the ferret, a few anchors, the docs and
/// GitHub.
class SiteNav extends StatelessComponent {
  const SiteNav();

  @override
  Component build(BuildContext context) => header(id: 'top', classes: 'nav', [
    nav(
      classes: 'nav-inner',
      attributes: {'aria-label': 'Main'},
      [
        const a(classes: 'nav-brand', href: '/', [
          img(src: SiteLinks.logo, alt: '', width: 28, height: 28),
          span([Component.text('Ferret')]),
        ]),
        ul(classes: 'nav-links', [
          _link('Features', '/#features', classes: 'nav-anchor'),
          _link('Privacy', '/#privacy', classes: 'nav-anchor'),
          _link('FAQ', '/#faq', classes: 'nav-anchor'),
          _link('Docs', SiteLinks.docs),
          _link('GitHub', SiteLinks.github),
        ]),
      ],
    ),
  ]);

  Component _link(String label, String href, {String? classes}) => li(
    classes: classes,
    [
      a(href: href, [Component.text(label)]),
    ],
  );
}
