import 'package:feature_kit/feature_kit.dart';
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
    return switch ((record.role, record.camera)) {
      (.shared, false) => auditShared(record.deviceName, length, at),
      (.viewed, false) => auditViewed(record.deviceName, length, at),
      (.shared, true) => cameraAuditShared(record.deviceName, length, at),
      (.viewed, true) => cameraAuditViewed(record.deviceName, length, at),
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

  /// Where the sound of the screen shown is, in a word or two.
  String soundDetail(ViewSound sound, {required bool on}) {
    if (!on) {
      return soundDetailThere;
    }

    return switch (sound) {
      .playing || .starting => soundDetailHere,
      .off => soundDetailThere,
      .unsupported || .notAllowed || .failed || .noOutput => soundDetailNone,
    };
  }

  /// What to know about the sound of [device]'s screen right now: why
  /// there is none, or what turning it on does.
  String soundNote(
    ViewSound sound, {
    required SoundWay way,
    required bool on,
    required String device,
  }) {
    if (way == .none) {
      return soundAirplay;
    }

    final explains = switch (way) {
      .copies => soundCopiesNote(device),
      _ => soundMovesNote(device),
    };
    if (!on) {
      return explains;
    }

    return switch (sound) {
      .playing => explains,
      .starting => soundWaiting,
      .off => soundNextTime(device),
      .notAllowed => soundNotAllowed(device),
      .unsupported => switch (way) {
        .copies => soundUnsupportedWifi(device),
        _ => soundUnsupportedCable(device),
      },
      .failed => soundFailed(device),
      .noOutput => soundNoOutput,
    };
  }

  /// Why the computer isn't showing the phone's camera, in a few words.
  /// What reads the same for a screen is said the same.
  String cameraEndTitle(ViewEnd end, String device) => switch (end) {
    .busy => cameraBusyTitle(device),
    .unsupported => cameraUnsupportedTitle(device),
    .turnedOff => cameraTurnedOffTitle(device),
    .cannotAsk => cameraCannotStartTitle(device),
    .systemEnded => cameraSystemEndedTitle(device),
    _ => endTitle(end, device),
  };

  /// What to do about it.
  String cameraEndBody(ViewEnd end, String device) => switch (end) {
    .denied => cameraDeniedBody(device),
    .busy => cameraBusyBody,
    .unsupported => cameraUnsupportedBody,
    .turnedOff => cameraTurnedOffBody(device, ThisComputer.here),
    .cannotAsk => cameraCannotStartBody(device),
    .stoppedHere => cameraStoppedHereBody(device),
    .systemEnded => cameraSystemEndedBody(device),
    .failed || .needsSetup => cameraFailedBody(device),
    _ => endBody(end, device),
  };

  /// Why the computer isn't showing the phone's screen, in a few words.
  String endTitle(ViewEnd end, String device) => switch (end) {
    .denied => endDeniedTitle(device),
    .timedOut => endTimedOutTitle(device),
    .busy => endBusyTitle(device),
    .unsupported => endUnsupportedTitle(device),
    .turnedOff => endTurnedOffTitle(device),
    .cannotAsk => endCannotAskTitle(device),
    .version => endVersionTitle(device),
    .noCodec => endNoCodecTitle(device, ThisComputer.here),
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
    .turnedOff => endTurnedOffBody(device, ThisComputer.here),
    .cannotAsk => endCannotAskBody(device),
    .version => endVersionBody(device),
    .noCodec => endNoCodecBody(device, ThisComputer.here),
    .notConnected => endNotConnectedBody(device, ThisComputer.here),
    .noAnswer => endNoAnswerBody(device),
    .stoppedHere => endStoppedHereBody(device),
    .stoppedOnPhone => endStoppedOnPhoneBody(device),
    .systemEnded => endSystemEndedBody(device),
    .lostConnection => endLostConnectionBody(device, ThisComputer.here),
    .failed || .needsSetup => endFailedBody(device),
    .decoderFailed => endDecoderFailedBody(device),
  };

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
    .back => buttonBack,
    .home => buttonHome,
    .recents => buttonRecents,
    .rotate => buttonRotate,
    .notifications => buttonNotifications,
    .volumeUp => buttonVolumeUp,
    .volumeDown => buttonVolumeDown,
    .power => buttonPower,
  };

  /// How a phone on a cable is connected.
  String targetLine(MirrorTarget target) => switch (target.wireless) {
    true => targetWireless,
    false => targetCable,
  };

  /// The way a screen arrives, in the words people use for it.
  String wayName(MirrorWay way) => switch (way) {
    .wifi => wayWifi,
    .cable => wayCable,
    .airplay => wayAirplay,
  };

  String qualityName(ViewQuality quality) => switch (quality) {
    .good => qualityGood,
    .slow => qualitySlow,
    .poor => qualityPoor,
  };

  String presetName(QualityPreset preset) => switch (preset) {
    .auto => presetAuto,
    .sharp => presetSharp,
    .fast => presetFast,
  };

  String presetBody(QualityPreset preset) => switch (preset) {
    .auto => presetAutoBody,
    .sharp => presetSharpBody,
    .fast => presetFastBody,
  };

  String codecName(MirrorCodec codec) => switch (codec) {
    .h264 => codecH264,
    .jpeg => codecJpeg,
  };

  /// "H.264 · 1080×2400 · 58 fps · 24 ms · 5.2 Mbps", with what is known:
  /// the numbers behind the quality mark, for those who ask.
  String statusLine(MirrorStreamConfig config, ViewStats stats) => [
    statusPicture(
      codecName(config.codec),
      config.width,
      config.height,
      stats.fps,
    ),
    if (stats.latencyMs case final latencyMs?) statusLatency(latencyMs),
    if (stats.bitrateKbps > 0)
      statusBitrate(
        NumberFormat('0.0', localeName).format(stats.bitrateKbps / 1000),
      ),
    if (stats.droppedFrames > 0) statusDropped(stats.droppedFrames),
  ].join(' · ');
}
