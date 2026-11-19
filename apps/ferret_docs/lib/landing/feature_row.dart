import 'package:ferret_docs/landing/feature_story.dart';
import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/rich_text.dart';
import 'package:ferret_docs/landing/themed_shot.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One feature group: the words on one side, the render on the other.
class FeatureRow extends StatelessComponent {
  const FeatureRow(this.story);

  final FeatureStory story;

  @override
  Component build(BuildContext context) {
    final titleId = '${story.id}-title';
    final layout = switch (story.frame) {
      ShotFrame.window when story.width >= story.height => 'wide',
      _ => 'tall',
    };

    return article(
      id: story.id,
      classes: 'feature feature-$layout reveal',
      attributes: {'aria-labelledby': titleId},
      [
        div(classes: 'feature-text', [
          h3(id: titleId, [Marker(story.emoji), Component.text(story.title)]),
          p(classes: 'feature-lead', richText(story.lead)),
          ul(classes: 'points', [
            for (final point in story.points) li(richText(point)),
          ]),
          a(classes: 'more', href: story.docs, [
            Component.text('${story.docsLabel} →'),
          ]),
        ]),
        div(classes: 'feature-shot', [
          ThemedShot(
            name: story.shot,
            alt: story.alt,
            width: story.width,
            height: story.height,
            classes: 'shot shot-${story.frame.name}',
          ),
        ]),
      ],
    );
  }
}
