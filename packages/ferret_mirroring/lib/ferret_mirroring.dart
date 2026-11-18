/// Platform code for Ferret's screen mirroring feature: capturing and
/// encoding an Android screen, decoding it on a computer, and the routes
/// a screen can arrive through.
library;

export 'package:ferret_mirroring/src/capture/android_screen_capture.dart';
export 'package:ferret_mirroring/src/capture/capture_event.dart';
export 'package:ferret_mirroring/src/capture/capture_options.dart';
export 'package:ferret_mirroring/src/capture/screen_capture.dart';
export 'package:ferret_mirroring/src/capture/unsupported_screen_capture.dart';
export 'package:ferret_mirroring/src/decoder/jpeg_mirror_decoder.dart';
export 'package:ferret_mirroring/src/decoder/mirror_decoder.dart';
export 'package:ferret_mirroring/src/decoder/mirror_picture.dart';
export 'package:ferret_mirroring/src/decoder/video_toolbox_decoder.dart';
export 'package:ferret_mirroring/src/messages.g.dart';
export 'package:ferret_mirroring/src/route/mirror_control.dart';
export 'package:ferret_mirroring/src/route/mirror_feed.dart';
export 'package:ferret_mirroring/src/route/mirror_route.dart';
export 'package:ferret_mirroring/src/route/mirror_target.dart';
export 'package:ferret_mirroring/src/stream/mirror_codec.dart';
export 'package:ferret_mirroring/src/stream/mirror_frame.dart';
export 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';
export 'package:ferret_mirroring/src/window/mirror_window.dart';
