import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/rich_text.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Free, open source, and how to help keep it that way.
class OpenSourceSection extends StatelessComponent {
  const OpenSourceSection();

  @override
  Component build(BuildContext context) => section(
    id: 'open-source',
    classes: 'open-source',
    attributes: {'aria-labelledby': 'open-source-title'},
    [
      div(classes: 'wrap', [
        div(classes: 'card oss-card reveal', [
          const h2(id: 'open-source-title', [
            Marker('🔓'),
            Component.text('Free and open source. Always.'),
          ]),
          p(
            richText(
              'The apps are **GPL-3.0**. The protocol is **MIT**, so anyone '
              'can build a compatible client. No paid tier, no ads, nothing '
              'locked away.',
            ),
          ),
          const p([
            Component.text(
              'If Ferret saves you time, you can sponsor me on GitHub. It '
              'keeps the lights on and the ferret fed.',
            ),
          ]),
          const div(classes: 'actions', [
            a(classes: 'button primary', href: SiteLinks.sponsor, [
              span(
                classes: 'marker',
                attributes: {'aria-hidden': 'true'},
                [
                  Component.text('❤️'),
                ],
              ),
              Component.text('Sponsor'),
            ]),
            a(classes: 'button', href: SiteLinks.github, [
              Component.text('Source on GitHub'),
            ]),
          ]),
        ]),
      ]),
    ],
  );
}
