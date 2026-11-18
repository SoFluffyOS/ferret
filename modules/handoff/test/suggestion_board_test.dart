import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';

import 'support/fakes.dart';

Suggestion _suggestion(
  String id, {
  HandoffPeer from = pixel,
  bool explicit = false,
  DateTime? expiresAt,
}) => Suggestion(
  activity: webActivity(id),
  from: from,
  isExplicit: explicit,
  receivedAt: DateTime(2026),
  expiresAt: expiresAt ?? DateTime(2026, 1, 1, 0, 5),
);

void main() {
  final now = DateTime(2026, 1, 1, 0, 1);

  test('a newer passive suggestion replaces the one from the same device', () {
    final board = SuggestionBoard();
    board.add(_suggestion('first'));

    final replaced = board.add(_suggestion('second'));

    expect(replaced.map((item) => item.id), ['first']);
    expect(board.live(now).map((item) => item.id), ['second']);
  });

  test('suggestions from different devices and explicit ones stay', () {
    final board = SuggestionBoard()
      ..add(_suggestion('pixel'))
      ..add(_suggestion('tablet', from: tablet))
      ..add(_suggestion('sent', explicit: true));

    board.add(_suggestion('pixel-newer'));

    expect(board.live(now).map((item) => item.id), [
      'pixel-newer',
      'sent',
      'tablet',
    ]);
  });

  test('expired suggestions are hidden, then pruned', () {
    final board = SuggestionBoard()
      ..add(_suggestion('old', expiresAt: DateTime(2026, 1, 1, 0, 0, 30)))
      ..add(_suggestion('fresh', from: tablet));

    expect(board.live(now).map((item) => item.id), ['fresh']);
    expect(board.nextExpiry, DateTime(2026, 1, 1, 0, 0, 30));
    expect(board.prune(now).map((item) => item.id), ['old']);
    expect(board.nextExpiry, DateTime(2026, 1, 1, 0, 5));
  });

  test('clearing removes one activity or everything from a device', () {
    final board = SuggestionBoard()
      ..add(_suggestion('a', explicit: true))
      ..add(_suggestion('b', explicit: true))
      ..add(_suggestion('c', from: tablet));

    expect(board.clearFrom(pixel.id, activityId: 'a').single.id, 'a');
    expect(board.clearFrom(pixel.id).single.id, 'b');
    expect(board.live(now).single.id, 'c');
  });

  test('the board keeps at most its capacity', () {
    final board = SuggestionBoard(capacity: 2)
      ..add(_suggestion('a', explicit: true))
      ..add(_suggestion('b', explicit: true));

    final dropped = board.add(_suggestion('c', explicit: true));

    expect(dropped.single.id, 'a');
    expect(board.live(now).map((item) => item.id), ['c', 'b']);
  });
}
