import 'dart:async';

import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/display/display_capture.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:ferret_mirroring/src/route/mirror_control.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// macOS: CGVirtualDisplay, captured with ScreenCaptureKit and encoded
/// with VideoToolbox.
class MacDisplayCapture implements DisplayCapture, DisplayCaptureFlutterApi {
  MacDisplayCapture({DisplayCaptureHostApi? api})
    : _api = api ?? DisplayCaptureHostApi() {
    DisplayCaptureFlutterApi.setUp(this);
  }

  final DisplayCaptureHostApi _api;
  final StreamController<CaptureEvent> _events = .broadcast(sync: true);

  @override
  Stream<CaptureEvent> get events => _events.stream;

  @override
  Future<DisplaySupport> support() async {
    final support = await _api.support();
    return DisplaySupport(
      canExtend: support.canExtend,
      screenRecordingGranted: support.screenRecordingGranted,
      inputGranted: support.inputGranted,
    );
  }

  @override
  Future<bool> requestScreenRecording() => _api.requestScreenRecording();

  @override
  Future<bool> requestInput() => _api.requestInput();

  @override
  Future<void> openScreenRecordingSettings() =>
      _api.openScreenRecordingSettings();

  @override
  Future<bool> start(DisplayCaptureOptions options) async {
    try {
      await _api.start(
        NativeDisplayOptions(
          name: options.name,
          serial: options.serial,
          width: options.width,
          height: options.height,
          scale: options.scale,
          refreshHz: options.refreshHz,
          bitrate: options.bitrate,
        ),
      );
      return true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stop() => _api.stop();

  @override
  Future<void> requestKeyframe() => _api.requestKeyframe();

  @override
  Future<void> setBitrate(int bitrate) => _api.setBitrate(bitrate);

  @override
  Future<void> pointer(MirrorPointer event) => _api.pointer(
    NativeDisplayPointer(
      phase: switch (event.phase) {
        .down => .down,
        .move => .move,
        .up || .cancel => .up,
        .hover => .hover,
        .scroll => .scroll,
      },
      x: event.x,
      y: event.y,
      button: _buttonOf(event.buttons),
      scrollX: event.scrollX,
      scrollY: event.scrollY,
    ),
  );

  @override
  Future<void> dispose() async {
    DisplayCaptureFlutterApi.setUp(null);
    await _events.close();
  }

  @override
  void onConfig(NativeStreamConfig config) => _add(
    CaptureConfigured(
      MirrorStreamConfig(
        codec: .h264,
        width: config.width,
        height: config.height,
        fps: config.fps,
        sps: config.sps,
        pps: config.pps,
      ),
    ),
  );

  @override
  void onFrame(NativeFrame frame) => _add(
    CaptureFrame(
      MirrorFrame(
        data: frame.data,
        ptsUs: frame.ptsUs,
        keyframe: frame.keyframe,
      ),
    ),
  );

  @override
  void onEnded(NativeCaptureEnd end) => _add(
    CaptureEnded(switch (end) {
      .stoppedByUser => .stoppedByUser,
      .endedBySystem => .endedBySystem,
      .failed => .failed,
    }),
  );

  /// 0 primary, 1 secondary, 2 middle, from Flutter's button bits.
  static int _buttonOf(int buttons) {
    if (buttons & kSecondaryMouseButton != 0) {
      return 1;
    }

    if (buttons & kMiddleMouseButton != 0) {
      return 2;
    }

    return 0;
  }

  void _add(CaptureEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
