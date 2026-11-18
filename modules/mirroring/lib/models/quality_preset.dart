import 'package:ferret_mirroring/ferret_mirroring.dart';

/// How the picture trades sharpness for smoothness. Stored by name.
enum QualityPreset {
  /// The route's own defaults, and the phone adapts its bitrate.
  auto,

  /// The phone's own size at the highest bitrate.
  sharp,

  /// A smaller picture that stays smooth on a slow connection.
  fast;

  static const _sharpBitrate = 8000000;
  static const _fastBitrate = 3000000;
  static const _fastLongSide = 1600;

  static QualityPreset named(String? name) {
    for (final preset in values) {
      if (preset.name == name) {
        return preset;
      }
    }

    return .auto;
  }

  /// What a route is asked for under this preset.
  FeedOptions options(List<MirrorCodec> codecs) => switch (this) {
    .auto => FeedOptions(codecs: codecs, control: true),
    .sharp => FeedOptions(
      codecs: codecs,
      control: true,
      bitrate: _sharpBitrate,
    ),
    .fast => FeedOptions(
      codecs: codecs,
      control: true,
      maxSize: _fastLongSide,
      bitrate: _fastBitrate,
    ),
  };
}
