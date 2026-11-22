import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

void main() {
  test(
    'a pairing link, at start or later, is opened; others are not',
    () async {
      final links = StreamController<Uri>();
      addTearDown(links.close);
      final opened = <String>[];
      final pairLinks = PairLinks(
        links: links.stream,
        initial: () async => Uri.parse('ferret://pair?o=first'),
        open: opened.add,
      );
      addTearDown(pairLinks.dispose);

      await pairLinks.start();
      links
        ..add(Uri.parse('https://example.com'))
        ..add(Uri.parse('ferret://pair?o=second'));
      await Future<void>.delayed(Duration.zero);

      expect(opened, ['ferret://pair?o=first', 'ferret://pair?o=second']);
    },
  );

  test('the link Ferret started with opens once, though the plugin also '
      'streams it', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final opened = <String>[];
    final first = Uri.parse('ferret://pair?o=first');
    final pairLinks = PairLinks(
      links: links.stream,
      initial: () async {
        links.add(first);
        await Future<void>.delayed(Duration.zero);
        return first;
      },
      latest: () async => first,
      open: opened.add,
    );
    addTearDown(pairLinks.dispose);

    await pairLinks.start();
    await Future<void>.delayed(Duration.zero);

    expect(opened, ['ferret://pair?o=first']);
  });

  test('a link that came while Ferret was getting ready is not lost', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final opened = <String>[];
    final pairLinks = PairLinks(
      links: links.stream,
      initial: () async => Uri.parse('ferret://pair?o=first'),
      latest: () async => Uri.parse('ferret://pair?o=while-starting'),
      open: opened.add,
    );
    addTearDown(pairLinks.dispose);

    await pairLinks.start();

    expect(opened, [
      'ferret://pair?o=first',
      'ferret://pair?o=while-starting',
    ]);
  });

  test('the same code scanned again later opens again', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final opened = <String>[];
    var now = DateTime(2026, 11, 22, 10);
    final pairLinks = PairLinks(
      links: links.stream,
      initial: () async => Uri.parse('ferret://pair?o=same'),
      open: opened.add,
      now: () => now,
    );
    addTearDown(pairLinks.dispose);

    await pairLinks.start();
    now = now.add(const Duration(minutes: 1));
    links.add(Uri.parse('ferret://pair?o=same'));
    await Future<void>.delayed(Duration.zero);

    expect(opened, ['ferret://pair?o=same', 'ferret://pair?o=same']);
  });
}
