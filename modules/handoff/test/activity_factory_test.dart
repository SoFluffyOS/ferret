import 'dart:convert';

import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';

void main() {
  group('shared text', () {
    test('a link with words becomes a titled web activity', () {
      final activity = ActivityFactory.fromText(
        'Read this https://example.org/post?id=1).',
      );

      expect(activity?.kind, ActivityKind.ACTIVITY_KIND_WEB);
      expect(activity?.uri, 'https://example.org/post?id=1');
      expect(activity?.title, 'Read this');
    });

    test('a bare link is titled by its host', () {
      final activity = ActivityFactory.fromText('https://www.example.org/a');

      expect(activity?.title, 'example.org');
    });

    test('a geo link becomes a place, and plain text stays text', () {
      expect(
        ActivityFactory.fromText('geo:1.5,2.5')?.kind,
        ActivityKind.ACTIVITY_KIND_GEO,
      );
      final note = ActivityFactory.fromText('  Buy milk\nand eggs ');
      expect(note?.kind, ActivityKind.ACTIVITY_KIND_TEXT);
      expect(note?.text, 'Buy milk\nand eggs');
      expect(note?.title, 'Buy milk');
    });

    test('empty text is nothing to send', () {
      expect(ActivityFactory.fromText('   '), isNull);
    });
  });

  group('assistant', () {
    SharedItem assist({
      String? webUri,
      String? deepLink,
      String? structuredData,
      String? text,
    }) => SharedItem(
      origin: .assistant,
      createdAtMs: 0,
      webUri: webUri,
      deepLink: deepLink,
      appPackage: 'org.wikipedia',
      appName: 'Wikipedia',
      structuredData: structuredData,
      title: 'Wikipedia',
      text: text,
    );

    test('the web URI and app intent become an app activity', () {
      final activity = ActivityFactory.fromShared(
        assist(
          webUri: 'https://en.wikipedia.org/wiki/Ferret',
          deepLink: 'wikipedia://en/Ferret',
        ),
      );

      expect(activity?.kind, ActivityKind.ACTIVITY_KIND_APP);
      expect(activity?.uri, 'https://en.wikipedia.org/wiki/Ferret');
      expect(activity?.deepLink, 'wikipedia://en/Ferret');
      expect(activity?.fallbackWebUri, 'https://en.wikipedia.org/wiki/Ferret');
      expect(activity?.apps.androidPackage, 'org.wikipedia');
      expect(activity?.sourceAppName, 'Wikipedia');
    });

    test('structured data from the app wins and travels as state', () {
      final json = jsonEncode({
        '@context': 'https://schema.org',
        '@type': 'Article',
        'name': 'Ferret',
        'url': 'https://example.org/ferret',
        'ferret': {
          'deepLink': 'notes://open/42',
          'apps': {'apple': 'org.example.Notes'},
        },
      });

      final activity = ActivityFactory.fromShared(
        assist(webUri: 'https://example.org/other', structuredData: json),
      );

      expect(activity?.title, 'Ferret');
      expect(activity?.uri, 'https://example.org/ferret');
      expect(activity?.deepLink, 'notes://open/42');
      expect(activity?.apps.appleBundleId, 'org.example.Notes');
      expect(activity?.stateType, 'application/ld+json');
      expect(utf8.decode(activity?.state ?? const []), json);
    });

    test('a place in structured data becomes a geo activity', () {
      final activity = ActivityFactory.fromShared(
        assist(
          structuredData: jsonEncode({
            '@type': 'Place',
            'name': 'Home',
            'geo': {'latitude': 48.85, 'longitude': '2.35'},
          }),
        ),
      );

      expect(activity?.kind, ActivityKind.ACTIVITY_KIND_GEO);
      expect(activity?.uri, 'geo:48.85,2.35');
    });

    test('phone-only intents are dropped; text is the last resort', () {
      final activity = ActivityFactory.fromShared(
        assist(deepLink: 'content://x/1', text: 'Some selected words'),
      );

      expect(activity?.kind, ActivityKind.ACTIVITY_KIND_TEXT);
      expect(activity?.deepLink, isEmpty);
    });
  });

  test('a browser tab is a web activity named after the browser', () {
    final activity = ActivityFactory.fromBrowserTab(
      BrowserTab(
        url: 'https://example.org',
        title: 'Example',
        browserBundleId: 'com.apple.Safari',
        browserName: 'Safari',
      ),
    );

    expect(activity.kind, ActivityKind.ACTIVITY_KIND_WEB);
    expect(activity.title, 'Example');
    expect(activity.sourceAppName, 'Safari');
  });
}
