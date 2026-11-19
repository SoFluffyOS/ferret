import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/rich_text.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Privacy as facts: what Ferret does, what it never does, and where every
/// byte that leaves a device is listed.
class PrivacySection extends StatelessComponent {
  const PrivacySection();

  @override
  Component build(BuildContext context) => section(
    id: 'privacy',
    classes: 'band privacy',
    attributes: {'aria-labelledby': 'privacy-title'},
    [
      div(classes: 'wrap privacy-inner', [
        const div(classes: 'section-head', [
          h2(id: 'privacy-title', [
            Marker('🔒'),
            Component.text('Ferret collects nothing.'),
          ]),
          p([
            Component.text(
              'Your stuff stays on your devices. That is the whole point.',
            ),
          ]),
        ]),
        ul(classes: 'facts', [
          for (final point in LandingContent.privacyPoints)
            li(classes: 'reveal', richText(point)),
        ]),
        const p(classes: 'section-foot', [
          Component.text('Every byte that goes anywhere is listed under '),
          strong([Component.text('What leaves this device')]),
          Component.text(' on the '),
          a(href: SiteLinks.privacy, [Component.text('privacy page')]),
          Component.text('.'),
        ]),
      ]),
    ],
  );
}
