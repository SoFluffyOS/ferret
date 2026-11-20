import 'package:ferret_docs/landing/marker.dart';
import 'package:ferret_docs/landing/rich_text.dart';
import 'package:ferret_docs/landing/site_links.dart';
import 'package:ferret_docs/landing/themed_shot.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The problem, then the fix: your own devices, paired once, on your Wi-Fi.
class TogetherSection extends StatelessComponent {
  const TogetherSection();

  static const _steps = [
    'Install Ferret on two devices on the same Wi-Fi.',
    'Tap **Pair** and check that both screens show the same six digits.',
    'That’s it. They find each other from now on.',
  ];

  @override
  Component build(BuildContext context) => section(
    classes: 'band together',
    attributes: {'aria-labelledby': 'together-title'},
    [
      div(classes: 'wrap split', [
        div(classes: 'split-text', [
          const h2(id: 'together-title', [
            Marker('user-x'),
            Component.text('Your devices, together. No account, no cloud.'),
          ]),
          const p([
            Component.text(
              'You copy something on your phone and need it on your laptop. '
              'A file sits on the wrong device. Your phone rings in the other '
              'room. Every fix out there wants an account, a cloud, or a '
              'phone from one brand.',
            ),
          ]),
          p([
            ...richText(
              '**Ferret** connects your own devices straight to each other, '
              'on the Wi-Fi you’re already on. Android, iPhone, Mac, Windows '
              'and Linux, in any mix.',
            ),
          ]),
          ol(classes: 'steps', [
            for (final step in _steps) li([span(richText(step))]),
          ]),
          const p([
            a(classes: 'more', href: SiteLinks.pairing, [
              Component.text('Pair your devices →'),
            ]),
          ]),
        ]),
        const div(classes: 'split-shot', [
          ThemedShot(
            name: 'pair-code',
            alt:
                'Pairing in Ferret: a six-digit code to check on the other '
                'device, with They match and Cancel',
            width: 760,
            height: 1120,
            classes: 'shot shot-popover',
          ),
        ]),
      ]),
    ],
  );
}
