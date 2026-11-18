import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:intl/intl.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';

/// Words for where mirroring stands, on either side.
extension MirroringLabels on MirroringLocalizations {
  /// "MacBook saw this phone's screen for 12 min at 21:10", or "You viewed
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
    .failed || .needsSetup => endFailedTitle,
    .decoderFailed => endDecoderFailedTitle,
  };

  /// What to do about it.
  String endBody(ViewEnd end, String device) => switch (end) {
    .denied => endDeniedBody(device),
    .timedOut => endTimedOutBody(device),
    .busy => endBusyBody,
    .unsupported => endUnsupportedBody,
    .turnedOff => endTurnedOffBody(device),
    .cannotAsk => endCannotAskBody(device),
    .version => endVersionBody(device),
    .noCodec => endNoCodecBody(device),
    .notConnected => endNotConnectedBody(device),
    .noAnswer => endNoAnswerBody(device),
    .stoppedHere => endStoppedHereBody(device),
    .stoppedOnPhone => endStoppedOnPhoneBody(device),
    .systemEnded => endSystemEndedBody(device),
    .lostConnection => endLostConnectionBody(device),
    .failed || .needsSetup => endFailedBody(device),
    .decoderFailed => endDecoderFailedBody(device),
  };

  /// The step a route still needs, as a headline anyone understands.
  String setupTitle(RouteSetup step) => switch (step) {
    .installTool => setupInstallToolTitle,
    .enableDebugging => setupEnableDebuggingTitle,
    .authorizeComputer => setupAuthorizeTitle,
    .grantPermission => setupPermissionTitle,
  };

  /// How to do that step. The route's own [detail], such as a path, goes
  /// on a line after it.
  String setupBody(RouteSetup step, {String? detail}) {
    final howTo = switch (step) {
      .installTool => setupInstallToolBody,
      .enableDebugging => setupEnableDebuggingBody,
      .authorizeComputer => setupAuthorizeBody,
      .grantPermission => setupPermissionBody,
    };
    if (detail == null || detail.isEmpty) {
      return howTo;
    }

    return '$howTo\n$detail';
  }

  /// What a receiver's switch says. Receivers this build doesn't know by
  /// name get the general words.
  String receiverTitle(String receiverId) => switch (receiverId) {
    'airplay' => receiverAirplayTitle,
    _ => receiverOtherTitle,
  };

  String receiverBody(String receiverId) => switch (receiverId) {
    'airplay' => receiverAirplayBody,
    _ => receiverOtherBody,
  };

  String buttonName(DeviceButton button) => switch (button) {
    .home => buttonHome,
    .recents => buttonRecents,
    _ => buttonBack,
  };

  /// How a device another route found is connected.
  String targetLine(MirrorTarget target) => switch (target.wireless) {
    true => targetWireless,
    false => targetCable,
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
