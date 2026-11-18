import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:intl/intl.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';

/// Words for where mirroring stands, on either side.
extension MirroringLabels on MirroringLocalizations {
  /// "MacBook viewed your screen for 12 min at 21:10", or "You viewed
  /// Pixel's screen for 12 min at 21:10" on the computer.
  String audit(MirrorRecord record) {
    final length = duration(record.duration);
    final at = time(record.startedAt);
    return switch (record.role) {
      .shared => auditShared(record.deviceName, length, at),
      .viewed => auditViewed(record.deviceName, length, at),
    };
  }

  String duration(Duration length) {
    if (length.inMinutes < 1) {
      return durationSeconds(length.inSeconds);
    }

    if (length.inHours < 1) {
      return durationMinutes(length.inMinutes);
    }

    return durationHours(length.inHours, length.inMinutes.remainder(60));
  }

  /// intl throws for a locale whose date symbols were never loaded; the
  /// default format beats no line at all.
  String time(DateTime at) {
    try {
      return DateFormat.Hm(localeName).format(at);
    } on Object {
      return DateFormat.Hm().format(at);
    }
  }

  /// Why the computer isn't showing the phone's screen, in a few words.
  String endTitle(ViewEnd end, String device) => switch (end) {
    .denied => endDeniedTitle(device),
    .timedOut => endTimedOutTitle(device),
    .busy => endBusyTitle(device),
    .unsupported => endUnsupportedTitle(device),
    .turnedOff => endTurnedOffTitle(device),
    .cannotAsk => endCannotAskTitle(device),
    .version => endVersionTitle(device),
    .noCodec => endNoCodecTitle(device),
    .notConnected => endNotConnectedTitle(device),
    .noAnswer => endNoAnswerTitle(device),
    .stoppedHere => endStoppedHereTitle,
    .stoppedOnPhone => endStoppedOnPhoneTitle(device),
    .systemEnded => endSystemEndedTitle(device),
    .lostConnection => endLostConnectionTitle(device),
    .failed => endFailedTitle,
    .decoderFailed => endDecoderFailedTitle,
  };

  /// What to do about it.
  String endBody(ViewEnd end, String device) => switch (end) {
    .denied => endDeniedBody,
    .timedOut => endTimedOutBody,
    .busy => endBusyBody,
    .unsupported => endUnsupportedBody,
    .turnedOff => endTurnedOffBody,
    .cannotAsk => endCannotAskBody,
    .version => endVersionBody,
    .noCodec => endNoCodecBody,
    .notConnected => endNotConnectedBody,
    .noAnswer => endNoAnswerBody,
    .stoppedHere => endStoppedHereBody(device),
    .stoppedOnPhone => endStoppedOnPhoneBody,
    .systemEnded => endSystemEndedBody,
    .lostConnection => endLostConnectionBody,
    .failed => endFailedBody(device),
    .decoderFailed => endDecoderFailedBody,
  };

  String codecName(MirrorCodec codec) => switch (codec) {
    .h264 => codecH264,
    .jpeg => codecJpeg,
  };

  /// "H.264 · 1080×2400 · 58 fps · 24 ms · 5.2 Mbps", with what is known.
  String statusLine(MirrorStreamConfig config, ViewStats stats) => [
    statusPicture(
      codecName(config.codec),
      config.width,
      config.height,
      stats.fps,
    ),
    if (stats.latencyMs case final latencyMs?) statusLatency(latencyMs),
    if (stats.bitrateKbps > 0)
      statusBitrate((stats.bitrateKbps / 1000).toStringAsFixed(1)),
    if (stats.droppedFrames > 0) statusDropped(stats.droppedFrames),
  ].join(' · ');
}
