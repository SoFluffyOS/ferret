import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/photos.dart';

void main() {
  final asked = DateTime(2026, 11, 19, 10);
  PhotoEntry shot(
    String id,
    DateTime at, {
    PhotoEntryKind kind = .screenshot,
  }) => PhotoEntry(id: id, takenAt: at, kind: kind);

  test('a new screenshot goes to a computer that asked and is shared', () {
    expect(
      ScreenshotRule.shouldSend(
        entry: shot('a', asked.add(const Duration(minutes: 1))),
        isShared: true,
        subscribedAt: asked,
        alreadySent: {},
      ),
      isTrue,
    );
  });

  test('never without sharing, without asking, or for a photo', () {
    final later = asked.add(const Duration(minutes: 1));

    expect(
      ScreenshotRule.shouldSend(
        entry: shot('a', later),
        isShared: false,
        subscribedAt: asked,
        alreadySent: {},
      ),
      isFalse,
    );
    expect(
      ScreenshotRule.shouldSend(
        entry: shot('a', later),
        isShared: true,
        subscribedAt: null,
        alreadySent: {},
      ),
      isFalse,
    );
    expect(
      ScreenshotRule.shouldSend(
        entry: shot('a', later, kind: .photo),
        isShared: true,
        subscribedAt: asked,
        alreadySent: {},
      ),
      isFalse,
    );
  });

  test('nothing old is replayed and nothing is sent twice', () {
    expect(
      ScreenshotRule.shouldSend(
        entry: shot('old', asked.subtract(const Duration(minutes: 5))),
        isShared: true,
        subscribedAt: asked,
        alreadySent: {},
      ),
      isFalse,
    );
    expect(
      ScreenshotRule.shouldSend(
        entry: shot('a', asked.add(const Duration(seconds: 1))),
        isShared: true,
        subscribedAt: asked,
        alreadySent: {'a'},
      ),
      isFalse,
    );
    expect(
      ScreenshotRule.shouldSend(
        entry: shot('lag', asked.subtract(const Duration(seconds: 2))),
        isShared: true,
        subscribedAt: asked,
        alreadySent: {},
      ),
      isTrue,
    );
  });
}
