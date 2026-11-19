import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

void main() {
  const control = <ToolbarItem>[
    .back,
    .home,
    .recents,
    .rotate,
    .keyboard,
    .quality,
    .fullScreen,
    .more,
    .stop,
  ];
  const viewOnly = <ToolbarItem>[.viewOnly, .quality, .more, .stop];

  test('with room, everything shows and nothing waits behind More', () {
    final fold = ToolbarFold.of(control, 420);

    expect(fold.shown, control);
    expect(fold.folded, isEmpty);
  });

  test('under 360, Rotate, Keyboard and Full screen move behind More', () {
    final fold = ToolbarFold.of(control, 359);

    expect(fold.shown, const <ToolbarItem>[
      .back,
      .home,
      .recents,
      .quality,
      .more,
      .stop,
    ]);
    expect(fold.folded, const <ToolbarItem>[.rotate, .keyboard, .fullScreen]);
  });

  test('under 280, only the phone\'s keys, More and Stop stay', () {
    final fold = ToolbarFold.of(control, 279);

    expect(fold.shown, const <ToolbarItem>[
      .back,
      .home,
      .recents,
      .more,
      .stop,
    ]);
    expect(fold.folded, const <ToolbarItem>[
      .rotate,
      .keyboard,
      .quality,
      .fullScreen,
    ]);
  });

  test('a toolbar that is wide enough but still too full folds one thing '
      'at a time, Screenshot first', () {
    const items = <ToolbarItem>[
      .viewOnly,
      .screenshot,
      .quality,
      .fullScreen,
      .more,
      .stop,
    ];
    double measure(List<ToolbarItem> shown) => shown.length * 80;

    final roomy = ToolbarFold.of(items, 480, measure: measure);
    final full = ToolbarFold.of(items, 400, measure: measure);

    expect(roomy.folded, isEmpty);
    expect(full.folded, const <ToolbarItem>[.screenshot]);
    expect(full.shown, contains(ToolbarItem.fullScreen));
  });

  test('the edges belong to the wider layout', () {
    expect(ToolbarFold.of(control, 360).folded, isEmpty);
    expect(ToolbarFold.of(control, 280).shown, contains(ToolbarItem.quality));
  });

  test('a device that is view only keeps its chip at any width', () {
    expect(ToolbarFold.of(viewOnly, 400).shown, viewOnly);
    expect(ToolbarFold.of(viewOnly, 200).shown, const <ToolbarItem>[
      .viewOnly,
      .more,
      .stop,
    ]);
  });

  test('Stop is never folded, and always comes last', () {
    for (final width in [200.0, 300.0, 500.0]) {
      expect(ToolbarFold.of(control, width).shown.last, ToolbarItem.stop);
    }
  });

  group('the quality mark', () {
    test('good with every frame shown and a short way', () {
      expect(
        ViewQuality.of(shownFrames: 58, droppedFrames: 0, latencyMs: 24),
        ViewQuality.good,
      );
    });

    test('a still screen sends few frames and is still good', () {
      expect(
        ViewQuality.of(shownFrames: 1, droppedFrames: 0),
        ViewQuality.good,
      );
    });

    test('slow with some frames dropped, or a longer way', () {
      expect(
        ViewQuality.of(shownFrames: 50, droppedFrames: 4, latencyMs: 30),
        ViewQuality.slow,
      );
      expect(
        ViewQuality.of(shownFrames: 60, droppedFrames: 0, latencyMs: 120),
        ViewQuality.slow,
      );
    });

    test('poor with half the frames gone, or a very long way', () {
      expect(
        ViewQuality.of(shownFrames: 10, droppedFrames: 10, latencyMs: 30),
        ViewQuality.poor,
      );
      expect(
        ViewQuality.of(shownFrames: 60, droppedFrames: 0, latencyMs: 260),
        ViewQuality.poor,
      );
    });
  });

  group('quality presets', () {
    const codecs = <MirrorCodec>[.h264, .jpeg];

    test('Auto leaves the size and the bitrate to the route', () {
      final options = QualityPreset.auto.options(codecs);

      expect(options.codecs, codecs);
      expect(options.maxSize, 0);
      expect(options.bitrate, 0);
      expect(options.control, isTrue);
    });

    test('Sharp keeps the full size at the top bitrate', () {
      final options = QualityPreset.sharp.options(codecs);

      expect(options.maxSize, 0);
      expect(options.bitrate, 8000000);
    });

    test('Fast asks for a smaller picture and less of the connection', () {
      final options = QualityPreset.fast.options(codecs);

      expect(options.maxSize, 1600);
      expect(options.bitrate, 3000000);
      expect(options.maxFps, 60);
    });

    test('a name it never stored reads as Auto', () {
      expect(QualityPreset.named(null), QualityPreset.auto);
      expect(QualityPreset.named('ultra'), QualityPreset.auto);
      expect(QualityPreset.named('fast'), QualityPreset.fast);
    });
  });

  test('the window\'s bar keeps the phone\'s keys, More and Stop, and the '
      'quality mark only while the picture is not good', () {
    expect(ToolbarFold.forBar(control).shown, const <ToolbarItem>[
      .back,
      .home,
      .recents,
      .more,
      .stop,
    ]);
    expect(ToolbarFold.forBar(control, showsQuality: true).shown, const [
      ToolbarItem.back,
      ToolbarItem.home,
      ToolbarItem.recents,
      ToolbarItem.quality,
      ToolbarItem.more,
      ToolbarItem.stop,
    ]);
    expect(ToolbarFold.forBar(viewOnly).shown, const <ToolbarItem>[
      .viewOnly,
      .more,
      .stop,
    ]);
  });

  group('away from its own window, the toolbar goes where the picture is '
      'bigger', () {
    const upright = Size(1080, 2400);
    const turned = Size(2400, 1080);
    ToolbarPlace placeOf(Size space, Size picture, {bool isSmall = false}) =>
        StageLayout.placeFor(
          space: space,
          picture: picture,
          belowExtent: 56,
          besideExtent: 200,
          isSmall: isSmall,
        );

    test('beside an upright phone in a wide pane', () {
      expect(placeOf(const Size(1000, 700), upright), ToolbarPlace.beside);
    });

    test('under a turned phone in the same pane', () {
      expect(placeOf(const Size(1000, 700), turned), ToolbarPlace.below);
    });

    test('under the picture in a tall window, and always on a phone', () {
      expect(placeOf(const Size(390, 844), upright), ToolbarPlace.below);
      expect(
        placeOf(const Size(900, 400), upright, isSmall: true),
        ToolbarPlace.below,
      );
    });
  });
}
