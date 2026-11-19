import 'package:ferret_docs/landing/feature_story.dart';
import 'package:ferret_docs/landing/landing_content.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Short, honest answers. Native `<details>`, so it needs no script.
class FaqSection extends StatelessComponent {
  const FaqSection();

  @override
  Component build(BuildContext context) => section(
    id: 'faq',
    classes: 'faq',
    attributes: {'aria-labelledby': 'faq-title'},
    [
      div(classes: 'wrap', [
        const div(classes: 'section-head', [
          h2(id: 'faq-title', [
            Marker('🙋'),
            Component.text('Questions.'),
          ]),
        ]),
        div(classes: 'faq-list', [
          for (final entry in LandingContent.faq) _entry(entry),
        ]),
      ]),
    ],
  );

  Component _entry(FaqEntry entry) {
    final answer = <Component>[Component.text(entry.answer)];
    if (entry.link case final link?) {
      answer.addAll([
        const Component.text(' '),
        a(href: link, [const Component.text('More →')]),
      ]);
    }

    return details(classes: 'faq-item', [
      summary([Component.text(entry.question)]),
      p(answer),
    ]);
  }
}
