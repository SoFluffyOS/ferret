import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

const _pixel = 'pixel';

LocalNotice _text({PrivateContent? private}) => LocalNotice(
  id: 'messages.pixel/1',
  channel: .incoming,
  title: 'Mom',
  body: 'Dinner at 7?',
  category: 'messages.message',
  private: private,
);

void main() {
  late MemorySettingsStore settings;
  late PrivatePreviews previews;
  late _Notices shown;
  var atScreen = true;

  setUp(() {
    settings = MemorySettingsStore();
    previews = PrivatePreviews(settings);
    shown = _Notices();
    atScreen = true;
  });

  PrivateNotifier notifier() => PrivateNotifier(
    shown,
    previews: previews,
    isAtScreen: () => atScreen,
    coverBody: () => 'Open Ferret to see it.',
  );

  const private = PrivateContent(_pixel, cover: 'New text on Pixel 7');

  group('previews', () {
    test('show on a computer one account uses', () {
      expect(previews.showsFrom(_pixel), isTrue);
      expect(previews.hasChoiceFor(_pixel), isFalse);
    });

    test('are off at first on a computer several accounts use', () async {
      await settings.set(SharedComputer.sharedKey, true);

      expect(previews.showsFrom(_pixel), isFalse);
    });

    test('follow the person\'s choice per device', () async {
      await settings.set(SharedComputer.sharedKey, true);
      await previews.setShows(_pixel, shows: true);
      await previews.setShows('ipad', shows: false);

      expect(previews.showsFrom(_pixel), isTrue);
      expect(previews.showsFrom('ipad'), isFalse);
      expect(previews.hasChoiceFor(_pixel), isTrue);
    });
  });

  group('notices', () {
    test('show as they are when nothing in them is private', () async {
      atScreen = false;

      await notifier().show(_text());

      expect(shown.last.title, 'Mom');
      expect(shown.last.body, 'Dinner at 7?');
    });

    test('show private content while someone is at the screen', () async {
      await notifier().show(_text(private: private));

      expect(shown.last.body, 'Dinner at 7?');
    });

    test('cover private content while the screen is locked', () async {
      atScreen = false;

      await notifier().show(_text(private: private));

      expect(shown.last.title, 'New text on Pixel 7');
      expect(shown.last.body, 'Open Ferret to see it.');
      expect(shown.last.image, isNull);
      expect(shown.last.category, 'messages.message');
      expect(shown.last.id, 'messages.pixel/1');
    });

    test(
      'cover private content from a device whose previews are off',
      () async {
        await previews.setShows(_pixel, shows: false);

        await notifier().show(_text(private: private));

        expect(shown.last.title, 'New text on Pixel 7');
        expect(shown.last.body, isNot(contains('Dinner')));
      },
    );
  });

  test('an Activity line covers its title and detail', () {
    const line = ActivityItem(
      id: 'messages.pixel/1',
      icon: IconData(0),
      title: 'Mom · Pixel 7',
      detail: 'Dinner at 7?',
      deviceId: _pixel,
      private: private,
    );

    final covered = line.covered('Hidden on this computer');

    expect(covered.title, 'New text on Pixel 7');
    expect(covered.detail, 'Hidden on this computer');
    expect(covered.deviceId, _pixel);
  });
}

class _Notices implements LocalNotifier {
  final List<LocalNotice> notices = [];

  LocalNotice get last => notices.last;

  @override
  Future<void> show(LocalNotice notice) async => notices.add(notice);

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}
