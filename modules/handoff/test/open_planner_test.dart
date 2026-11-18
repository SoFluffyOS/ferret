import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';

void main() {
  final article = Activity(
    id: '1',
    kind: .ACTIVITY_KIND_APP,
    title: 'Ferret',
    uri: 'https://en.wikipedia.org/wiki/Ferret',
    deepLink: 'wikipedia://en/Ferret',
    apps: AppIdentifiers(
      androidPackage: 'org.wikipedia',
      appleBundleId: 'org.wikimedia.wikipedia',
    ),
    fallbackWebUri: 'https://en.m.wikipedia.org/wiki/Ferret',
  );

  test('the app deep link comes first, then the web fallback', () {
    expect(OpenPlanner.plan(article, .PLATFORM_ANDROID), [
      const OpenInApp('wikipedia://en/Ferret', 'org.wikipedia'),
      const OpenLink('wikipedia://en/Ferret', appsOnly: true),
      const OpenInApp(
        'https://en.wikipedia.org/wiki/Ferret',
        'org.wikipedia',
      ),
      const OpenLink('https://en.wikipedia.org/wiki/Ferret'),
      const OpenLink('https://en.m.wikipedia.org/wiki/Ferret'),
    ]);
  });

  test('each platform uses its own app id', () {
    expect(
      OpenPlanner.plan(article, .PLATFORM_MACOS).first,
      const OpenInApp('wikipedia://en/Ferret', 'org.wikimedia.wikipedia'),
    );
    expect(
      OpenPlanner.plan(article, .PLATFORM_LINUX).first,
      const OpenLink('wikipedia://en/Ferret', appsOnly: true),
    );
  });

  test('without an app, a web page just opens', () {
    final page = Activity(
      id: '2',
      kind: .ACTIVITY_KIND_WEB,
      uri: 'https://example.org',
    );

    expect(OpenPlanner.plan(page, .PLATFORM_WINDOWS), [
      const OpenLink('https://example.org'),
    ]);
  });

  test('links to local files or scripts are never opened', () {
    final hostile = Activity(
      id: '3',
      kind: .ACTIVITY_KIND_APP,
      uri: 'file:///etc/passwd',
      deepLink: 'javascript:alert(1)',
      fallbackWebUri: 'content://contacts/people',
    );

    expect(OpenPlanner.plan(hostile, .PLATFORM_ANDROID), isEmpty);
  });

  test('places open in the maps each platform has', () {
    final place = Activity(
      id: '4',
      kind: .ACTIVITY_KIND_GEO,
      uri: 'geo:48.8584,2.2945?q=Eiffel%20Tower',
    );

    expect(
      OpenPlanner.plan(place, .PLATFORM_ANDROID).first,
      const OpenLink(
        'geo:48.8584,2.2945?q=Eiffel%20Tower',
      ),
    );
    expect(
      (OpenPlanner.plan(place, .PLATFORM_MACOS).single as OpenLink).uri,
      startsWith('https://maps.apple.com/?ll=48.8584%2C2.2945'),
    );
    expect(
      (OpenPlanner.plan(place, .PLATFORM_LINUX).last as OpenLink).uri,
      contains('openstreetmap.org'),
    );
  });

  test('text is copied', () {
    final note = Activity(id: '5', kind: .ACTIVITY_KIND_TEXT, text: 'Milk');

    expect(OpenPlanner.plan(note, .PLATFORM_MACOS), [const CopyText('Milk')]);
  });
}
