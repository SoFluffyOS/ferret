import 'dart:typed_data';

import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:ferret_clipboard/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads text with its private flag', () async {
    final api = _FakeHostApi()
      ..clip = PlatformClip(text: 'hello', sensitive: true);
    final clipboard = PigeonClipboard(api: api, access: .always);

    final content = await clipboard.read();

    expect(content?.text, 'hello');
    expect(content?.sensitive, isTrue);
  });

  test('reads images and ignores empty clips', () async {
    final api = _FakeHostApi()
      ..clip = PlatformClip(
        image: Uint8List.fromList([1, 2, 3]),
        imageMime: 'image/png',
        sensitive: false,
      );
    final clipboard = PigeonClipboard(api: api, access: .always);

    final image = await clipboard.read();
    api.clip = PlatformClip(text: '', sensitive: false);
    final empty = await clipboard.read();

    expect(image?.isImage, isTrue);
    expect(image?.imageMime, 'image/png');
    expect(empty, isNull);
  });

  test('writes what it is given and reports native changes', () async {
    final api = _FakeHostApi();
    final clipboard = PigeonClipboard(api: api, access: .foreground);
    final changed = clipboard.changes.first;

    await clipboard.write(const .text('secret', sensitive: true));
    clipboard.onChanged();

    expect(api.written?.text, 'secret');
    expect(api.written?.sensitive, isTrue);
    await changed;
  });

  test('only desktops watch other apps', () {
    expect(ClipboardAccess.always.watchesOtherApps, isTrue);
    expect(ClipboardAccess.foreground.watchesOtherApps, isFalse);
    expect(ClipboardAccess.onRequest.watchesOtherApps, isFalse);
  });
}

class _FakeHostApi extends ClipboardHostApi {
  PlatformClip? clip;
  PlatformClip? written;

  @override
  Future<PlatformClip?> read() async => clip;

  @override
  Future<void> write(PlatformClip clip) async => written = clip;

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}
}
