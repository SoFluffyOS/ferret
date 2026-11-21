import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

TrustedDevice _device(String id, String name) => TrustedDevice(
  id: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026),
);

final _pixel = _device('aaaaaaaaaaaaaaaa', 'Pixel 7');
final _ipad = _device('bbbbbbbbbbbbbbbb', "Anna's iPad");
final _now = DateTime(2026, 11, 21, 12);

void main() {
  Future<List<(GroupRequest, bool)>> show(
    WidgetTester tester,
    GroupRequest request,
  ) async {
    final answers = <(GroupRequest, bool)>[];
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            final items = GroupRequestItems.build(
              context.shellL10n,
              LocalNames.hereMac,
              [request],
              onAnswer: (request, {required yes}) =>
                  answers.add((request, yes)),
            );
            return Column(
              children: [
                for (final item in items) ActivityRow(item: item, now: _now),
              ],
            );
          },
        ),
      ),
    );
    return answers;
  }

  testWidgets('an addition asks with Add and Not now, and nothing else', (
    tester,
  ) async {
    final request = JoinRequest(
      device: _ipad,
      introducer: _pixel,
      askedAt: _now,
      expiresAt: _now.add(const Duration(hours: 24)),
    );

    final answers = await show(tester, request);

    expect(
      find.text("Pixel 7 wants to add Anna's iPad to your devices"),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel("Add Anna's iPad to this Mac"),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel("Keep Anna's iPad off this Mac"),
      findsOneWidget,
    );
    await tester.tap(find.text('Not now'));
    await tester.tap(find.text('Add'));
    expect(answers, [(request, false), (request, true)]);
  });

  testWidgets('a removal asks with Remove and Keep', (tester) async {
    final request = RemovalRequest(
      device: _ipad,
      introducer: _pixel,
      askedAt: _now,
      expiresAt: _now.add(const Duration(hours: 24)),
      forgottenAt: _now,
    );

    final answers = await show(tester, request);

    expect(
      find.text("Pixel 7 wants to remove Anna's iPad from this Mac"),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep'));
    await tester.tap(find.text('Remove'));
    expect(answers, [(request, false), (request, true)]);
  });

  testWidgets('a request waits under Needs you and holds the primary', (
    tester,
  ) async {
    late ActivityFeed feed;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            feed = ActivityFeed.of(
              GroupRequestItems.build(
                context.shellL10n,
                LocalNames.hereMac,
                [
                  JoinRequest(
                    device: _ipad,
                    introducer: _pixel,
                    askedAt: _now,
                    expiresAt: _now,
                  ),
                ],
                onAnswer: (_, {required yes}) {},
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(feed.needsYou, hasLength(1));
    expect(feed.recent, isEmpty);
    expect(feed.primaryItem, same(feed.needsYou.single));
  });
}
