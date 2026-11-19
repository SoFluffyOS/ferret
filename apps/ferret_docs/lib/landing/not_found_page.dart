import 'package:ferret_docs/landing/site_footer.dart';
import 'package:ferret_docs/landing/site_head.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:ferret_docs/landing/site_nav.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

/// The page a host shows for a missing path. The docs used to live at the
/// root, so an old docs link is sent on to `/docs/...` by a few lines of
/// script, and the page itself still offers the way there.
class NotFoundPage extends StatelessComponent {
  const NotFoundPage();

  static const _movedDocsScript = r'''
(function () {
  var moved = ["getting-started", "features", "android-modes", "iphone", "interop", "spec", "contributing", "privacy"];
  var path = location.pathname.replace(/^\/+/, "");
  var first = path.split("/")[0].replace(/\.html$/, "");
  if (moved.indexOf(first) >= 0) {
    location.replace("/docs/" + path + location.search + location.hash);
  }
})();
''';

  @override
  Component build(BuildContext context) => Document(
    title: 'Not found · Ferret',
    lang: 'en',
    head: [
      ...siteHead(
        title: 'Not found · Ferret',
        description: 'This page isn’t here. The docs live at /docs.',
        path: '/404.html',
      ),
      const meta(name: 'robots', content: 'noindex'),
      const script(content: _movedDocsScript),
    ],
    body: const Component.fragment([
      SiteNav(),
      main_(id: 'main', classes: 'not-found', [
        div(classes: 'wrap narrow', [
          img(src: SiteLinks.logo, alt: '', width: 96, height: 96),
          h1([Component.text('This page ran off.')]),
          p([
            Component.text(
              'Ferrets do that. The docs moved to /docs, so an old link may '
              'land here.',
            ),
          ]),
          div(classes: 'actions', [
            a(classes: 'button primary', href: SiteLinks.docs, [
              Component.text('Open the docs'),
            ]),
            a(classes: 'button', href: '/', [Component.text('Home')]),
          ]),
        ]),
      ]),
      SiteFooter(),
    ]),
  );
}
