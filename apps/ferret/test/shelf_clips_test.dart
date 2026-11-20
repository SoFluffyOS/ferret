import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret/wiring/wiring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';

class _Host implements FeatureHost {
  @override
  final MemorySettingsStore settings = MemorySettingsStore();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Host host;
  late ShelfFeature shelf;
  late StreamController<ClipCopy> copies;
  late ShelfClips clips;

  setUp(() async {
    host = _Host();
    shelf = ShelfFeature();
    await shelf.start(host);
    copies = StreamController<ClipCopy>.broadcast();
  });

  tearDown(() async {
    await clips.cancel();
    await shelf.stop();
    await copies.close();
  });

  test('nobody listens to the clipboard while Keep copies is off', () async {
    clips = ShelfClips.follow(shelf, copies.stream);

    expect(clips.isListening, isFalse);
    expect(copies.hasListener, isFalse);
  });

  test(
    'listens while Keep copies is on, and lets go when it turns off',
    () async {
      clips = ShelfClips.follow(shelf, copies.stream);

      await shelf.settings.setKeepCopies(true);
      await pumpEventQueue();
      expect(copies.hasListener, isTrue);

      await shelf.settings.setKeepCopies(false);
      await pumpEventQueue();
      expect(copies.hasListener, isFalse);
    },
  );

  test('already on at launch: listens from the start', () async {
    await host.settings.set(ShelfSettings.keepCopiesKey, true);

    clips = ShelfClips.follow(shelf, copies.stream);

    expect(copies.hasListener, isTrue);
  });
}
