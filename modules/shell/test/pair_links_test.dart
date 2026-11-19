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
}
