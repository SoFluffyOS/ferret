import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an entry reads what the platform sends', () {
    final entry = PhotoEntry.fromMap({
      'id': 'i:42',
      'takenAtMs': 1700000000000,
      'kind': 'screenshot',
      'width': 1080,
      'height': 2400,
      'size': 512000,
      'name': 'Screenshot_1.png',
    });

    expect(entry?.id, 'i:42');
    expect(entry?.kind, PhotoEntryKind.screenshot);
    expect(entry?.takenAt.millisecondsSinceEpoch, 1700000000000);
    expect(entry?.width, 1080);
    expect(entry?.size, 512000);
    expect(entry?.duration, Duration.zero);
  });

  test('an entry without an id is dropped, odd values read as zero', () {
    expect(PhotoEntry.fromMap({'kind': 'photo'}), isNull);
    expect(PhotoEntry.fromMap('nope'), isNull);

    final entry = PhotoEntry.fromMap({'id': 'x', 'width': -3, 'kind': 'gif'});
    expect(entry?.width, 0);
    expect(entry?.kind, PhotoEntryKind.photo);
  });

  test('a page keeps its cursor and skips broken entries', () {
    final page = PhotoPage.fromMap({
      'entries': [
        {'id': 'a', 'takenAtMs': 2},
        {'name': 'no id'},
        {'id': 'b', 'takenAtMs': 1},
      ],
      'nextCursor': '1:b',
    });

    expect([for (final entry in page.entries) entry.id], ['a', 'b']);
    expect(page.nextCursor, '1:b');
    expect(
      PhotoPage.fromMap({'entries': [], 'nextCursor': ''}).nextCursor,
      isNull,
    );
  });

  test('access names map back, unknown ones read as unavailable', () {
    expect(PhotoLibraryAccess.byNameOr('limited'), PhotoLibraryAccess.limited);
    expect(PhotoLibraryAccess.byNameOr(null), PhotoLibraryAccess.unavailable);
    expect(PhotoLibraryAccess.limited.canRead, isTrue);
    expect(PhotoLibraryAccess.denied.canRead, isFalse);
  });

  test('a computer has no library', () async {
    const library = UnsupportedPhotoLibrary();

    expect(library.isSupported, isFalse);
    expect(await library.access(), PhotoLibraryAccess.unsupported);
    expect((await library.list()).entries, isEmpty);
  });
}
