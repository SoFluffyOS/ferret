import 'package:ferret_docs/landing/feature_row.dart';
import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/rich_text.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Every feature group with a real render, then the smaller extras.
class FeaturesSection extends StatelessComponent {
  const FeaturesSection();

  @override
  Component build(BuildContext context) => section(
    id: 'features',
    classes: 'features',
    attributes: {'aria-labelledby': 'features-title'},
    [
      div(classes: 'wrap', [
        const div(classes: 'section-head', [
          h2(id: 'features-title', [
            Marker('✨'),
            Component.text('What you can do.'),
          ]),
          p([
            Component.text(
              'Pick what you need. Everything else stays off until you turn '
              'it on.',
            ),
          ]),
        ]),
        for (final story in LandingContent.stories) FeatureRow(story),
        ul(classes: 'extras', [
          for (final extra in LandingContent.extras)
            li(classes: 'extra reveal', [
              h3([Marker(extra.emoji), Component.text(extra.title)]),
              p(richText(extra.body)),
              a(classes: 'more', href: extra.docs, [
                const Component.text('Read more'),
                span(classes: 'visually-hidden', [
                  Component.text(' about ${extra.title.toLowerCase()}'),
                ]),
                const Component.text(' →'),
              ]),
            ]),
        ]),
        const p(classes: 'section-foot', [
          Component.text('Every feature has its own page in the '),
          a(href: SiteLinks.docs, [Component.text('docs')]),
          Component.text('.'),
        ]),
      ]),
    ],
  );
}
