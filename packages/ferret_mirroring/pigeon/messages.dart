import 'package:pigeon/pigeon.dart';

// Regenerate with `fvm dart run pigeon --input pigeon/messages.dart` from the
// package folder. Android captures and encodes the screen; macOS decodes
// H.264 into a texture. JPEG decoding is Dart only (lib/src/decoder/).
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_mirroring',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_mirroring/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_mirroring'),
    swiftOut:
        'macos/ferret_mirroring/Sources/ferret_mirroring/Messages.g.swift',
  ),
)
enum NativeCodec { h264, jpeg }

/// What this device can capture with.
class NativeCaptureSupport {
  NativeCaptureSupport({required this.h264, required this.jpeg});

  /// A hardware or software H.264 encoder is there.
  bool h264;
  bool jpeg;
}

enum NativeConsentResult {
  /// The owner allowed this capture on the system prompt.
  granted,

  /// The owner said no, or closed the prompt.
  denied,

  /// Nobody answered in time, or the request was cancelled.
  timedOut,

  /// The prompt couldn't be shown: the app is in the background and may
  /// not post notices.
  cannotAsk,

  /// The system refused to start the capture service.
  failed,
}

/// The words on the prompt notice, in the owner's language.
class NativeConsentTexts {
  NativeConsentTexts({
    required this.askTitle,
    required this.askBody,
    required this.askChannelName,
    required this.sharingTitle,
    required this.sharingBody,
    required this.stopLabel,
    required this.sharingChannelName,
  });

  /// Such as "MacBook wants to see this screen".
  String askTitle;

  /// Such as "Tap to answer".
  String askBody;
  String askChannelName;

  /// The ongoing notice, such as "Sharing screen with MacBook".
  String sharingTitle;
  String sharingBody;
  String stopLabel;
  String sharingChannelName;
}

class NativeCaptureOptions {
  NativeCaptureOptions({
    required this.codec,
    required this.maxLongSide,
    required this.maxShortSide,
    required this.fps,
    required this.bitrate,
    this.audioCodec,
  });

  NativeCodec codec;
  int maxLongSide;
  int maxShortSide;
  int fps;

  /// Bits per second the H.264 encoder starts with.
  int bitrate;

  /// Also capture what the device plays, encoded this way. Null for
  /// pictures only.
  NativeAudioCodec? audioCodec;
}

/// Whether this device can capture what it plays.
enum NativeAudioSupport {
  /// Android 9 or older.
  unsupported,

  /// Android wants its "record audio" permission first, though only what
  /// the device plays is captured, never the microphone.
  needsPermission,

  ready,
}

class NativeStreamConfig {
  NativeStreamConfig({
    required this.codec,
    required this.width,
    required this.height,
    required this.rotation,
    required this.fps,
    this.sps,
    this.pps,
    this.turn,
  });

  NativeCodec codec;
  int width;
  int height;

  /// Degrees clockwise: 0, 90, 180 or 270.
  int rotation;
  int fps;

  /// H.264 parameter sets, each one NAL unit without a start code.
  Uint8List? sps;
  Uint8List? pps;

  /// A camera only: degrees clockwise to turn the picture so it shows
  /// upright. Null for a screen, which is upright already.
  int? turn;
}

class NativeFrame {
  NativeFrame({
    required this.data,
    required this.ptsUs,
    required this.keyframe,
  });

  /// H.264: one Annex-B access unit. JPEG: the picture.
  Uint8List data;
  int ptsUs;
  bool keyframe;
}

enum NativeCaptureEnd {
  /// Stop on the ongoing notice.
  stoppedByUser,

  /// The system ended the capture, such as when the phone was locked.
  endedBySystem,

  /// The encoder or the capture failed.
  failed,
}

/// Android: captures the screen with MediaProjection.
@HostApi()
abstract class MirrorCaptureHostApi {
  NativeCaptureSupport support();

  /// Shows the system's screen capture prompt, every time. When the app is
  /// in the background, a notice leads to it. A yes starts the foreground
  /// service with its ongoing notice; the grant is used once by [start]
  /// and never kept.
  @async
  NativeConsentResult requestConsent(
    NativeConsentTexts texts,
    int timeoutSeconds,
  );

  NativeAudioSupport audioSupport();

  /// Shows Android's permission prompt for capturing sound. False when
  /// the owner said no, or no screen of the app is open to ask from.
  @async
  bool requestAudioPermission();

  /// Takes back a [requestConsent] that hasn't been answered.
  void cancelConsent();

  /// Starts the capture and the encoder with the grant from
  /// [requestConsent]. Returns false when there is none or it failed.
  @async
  bool start(NativeCaptureOptions options);

  void stop();

  void requestKeyframe();

  void setBitrate(int bitrate);
}

@FlutterApi()
abstract class MirrorCaptureFlutterApi {
  void onConfig(NativeStreamConfig config);

  void onFrame(NativeFrame frame);

  void onScreenOff(bool off);

  /// Sound follows, encoded this way.
  void onAudioConfig(NativeAudioCodec codec, int sampleRate, int channels);

  /// Opus: one packet. PCM: whole samples for every channel.
  void onAudioFrame(Uint8List data, int ptsUs);

  /// Capturing the sound stopped working; the pictures go on.
  void onAudioEnded();

  void onEnded(NativeCaptureEnd end);
}

enum NativeCameraLens {
  /// Faces away from the screen.
  back,

  /// Faces whoever looks at the screen.
  front,
}

/// What this device's cameras can do for a computer, as things stand.
class NativeCameraSupport {
  NativeCameraSupport({
    required this.h264,
    required this.lenses,
    required this.cameraGranted,
    required this.microphoneGranted,
  });

  /// A hardware or software H.264 encoder is there.
  bool h264;

  /// The cameras there are. Empty on a device without one.
  List<NativeCameraLens> lenses;

  /// Android's camera permission is granted.
  bool cameraGranted;

  /// Android's microphone permission is granted.
  bool microphoneGranted;
}

class NativeCameraOptions {
  NativeCameraOptions({
    required this.lens,
    required this.maxLongSide,
    required this.maxShortSide,
    required this.fps,
    required this.bitrate,
    this.audioCodec,
  });

  /// The camera to start with. Another one is used when it isn't there.
  NativeCameraLens lens;
  int maxLongSide;
  int maxShortSide;
  int fps;

  /// Bits per second the H.264 encoder starts with.
  int bitrate;

  /// Also capture the microphone, encoded this way. Null for pictures
  /// only.
  NativeAudioCodec? audioCodec;
}

/// The words on the ongoing notice while the camera is on, in the owner's
/// language.
class NativeCameraTexts {
  NativeCameraTexts({
    required this.title,
    required this.body,
    required this.stopLabel,
    required this.channelName,
  });

  /// Such as "Camera on for MacBook".
  String title;
  String body;
  String stopLabel;
  String channelName;
}

/// Android: sends a camera and the microphone with Camera2, from a
/// foreground service with an ongoing notice.
@HostApi()
abstract class CameraCaptureHostApi {
  NativeCameraSupport support();

  /// Shows Android's permission prompt for the camera, and for the
  /// microphone with [withMicrophone], when they aren't granted yet.
  /// Answers with how things stand afterwards; nothing is asked when no
  /// screen of the app is open.
  @async
  NativeCameraSupport requestAccess(bool withMicrophone);

  /// Starts the foreground service, the camera and the encoder. Answers
  /// with the camera that is on, or null when it couldn't start: no
  /// permission, no camera, or Android doesn't let a camera start from
  /// the background.
  @async
  NativeCameraLens? start(NativeCameraOptions options, NativeCameraTexts texts);

  /// Switches to another camera while one is on. Answers with the camera
  /// that is on afterwards, or null when none is.
  @async
  NativeCameraLens? setLens(NativeCameraLens lens);

  void stop();

  void requestKeyframe();

  void setBitrate(int bitrate);
}

@FlutterApi()
abstract class CameraCaptureFlutterApi {
  void onConfig(NativeStreamConfig config);

  void onFrame(NativeFrame frame);

  /// The microphone's sound follows, encoded this way.
  void onAudioConfig(NativeAudioCodec codec, int sampleRate, int channels);

  /// Opus: one packet. PCM: whole samples for every channel.
  void onAudioFrame(Uint8List data, int ptsUs);

  /// Capturing the microphone stopped working; the pictures go on.
  void onAudioEnded();

  void onEnded(NativeCaptureEnd end);
}

/// Decodes H.264 into a Flutter texture: VideoToolbox on macOS, MediaCodec
/// on Android.
@HostApi()
abstract class MirrorDecoderHostApi {
  /// Registers the texture pictures are drawn to and returns its id.
  int create();

  /// Sets up the decoder for these parameter sets (NAL units without start
  /// codes). Throws when VideoToolbox refuses them.
  void configure(Uint8List sps, Uint8List pps);

  /// Decodes one Annex-B access unit. Results arrive through
  /// [MirrorDecoderFlutterApi].
  void decode(Uint8List data, int ptsUs, bool keyframe);

  void dispose();

  /// Saves the picture that is on the texture right now as a PNG file at
  /// [path], making its folder when it isn't there. False when there is no
  /// picture yet or the file couldn't be written.
  @async
  bool savePicture(String path);

  /// Whether the window showing Flutter can go full screen.
  bool canFullScreen();

  bool isFullScreen();

  void setFullScreen(bool fullScreen);
}

@FlutterApi()
abstract class MirrorDecoderFlutterApi {
  /// A picture reached the texture.
  void onDecoded(int ptsUs, int width, int height);

  /// A frame couldn't be decoded; the next one must be a keyframe.
  void onDecodeError(int status);

  /// Android: the texture's buffers are [bufferWidth] × [bufferHeight] and
  /// only the part from ([cropLeft], [cropTop]) the size [onDecoded] gives
  /// is the picture. Sent before the first picture of a new size, only
  /// where Flutter doesn't cut the buffers itself.
  void onBufferSize(
    int bufferWidth,
    int bufferHeight,
    int cropLeft,
    int cropTop,
  );
}

/// Android: the screen of the activity Flutter draws in, while it shows
/// another computer's display.
@HostApi()
abstract class MirrorScreenHostApi {
  /// Keeps the screen on while [on], however long nobody touches it.
  void keepScreenOn(bool on);
}

enum NativeAudioCodec {
  /// Opus, one packet per call.
  opus,

  /// Signed 16-bit little-endian samples, channels interleaved.
  pcm,
}

class NativeAudioStats {
  NativeAudioStats({required this.frames, required this.peak});

  /// Samples per channel decoded since the last configure.
  int frames;

  /// The loudest decoded sample since then, from 0 to 1.
  double peak;
}

/// macOS: plays a mirrored device's sound through AVAudioEngine, decoding
/// Opus with AudioToolbox.
@HostApi()
abstract class MirrorAudioHostApi {
  /// Gets ready for a stream. With [silent], sound is decoded and measured
  /// but the speakers are never opened. Throws when the stream can't be
  /// played.
  void configure(
    NativeAudioCodec codec,
    int sampleRate,
    int channels,
    bool silent,
  );

  /// Decodes [data] and queues it right after what was queued before.
  void play(Uint8List data);

  /// Drops what is queued and hasn't played yet.
  void flush();

  /// From 0 to 1.
  void setVolume(double volume);

  NativeAudioStats stats();

  void close();
}

/// What this computer can do as the source of an extra display.
class NativeDisplaySupport {
  NativeDisplaySupport({
    required this.canExtend,
    required this.screenRecordingGranted,
    required this.inputGranted,
  });

  /// The system lets an app make a display, capture it and encode it.
  bool canExtend;

  /// The system lets this app see what is on its screens.
  bool screenRecordingGranted;

  /// The system lets this app move the pointer and press keys.
  bool inputGranted;
}

class NativeDisplayOptions {
  NativeDisplayOptions({
    required this.name,
    required this.serial,
    required this.width,
    required this.height,
    required this.scale,
    required this.refreshHz,
    required this.bitrate,
  });

  /// What the display is called in the system's display settings.
  String name;

  /// The same for the same viewer every time, so the system keeps where
  /// its owner put the display.
  int serial;

  /// The viewer's screen in pixels.
  int width;
  int height;

  /// Pixels per point: 1 or 2.
  int scale;
  int refreshHz;

  /// Bits per second the encoder starts with.
  int bitrate;
}

/// This computer's own screen, for another computer that makes a display
/// to fill it.
class NativeScreenPanel {
  NativeScreenPanel({
    required this.width,
    required this.height,
    required this.scale,
    required this.refreshHz,
  });

  /// In pixels.
  int width;
  int height;

  /// Pixels per point.
  int scale;
  int refreshHz;
}

enum NativePointerPhase { down, move, up, hover, scroll }

/// The viewer's pointer on the extra display. [x] and [y] are fractions
/// of the display's width and height.
class NativeDisplayPointer {
  NativeDisplayPointer({
    required this.phase,
    required this.x,
    required this.y,
    required this.button,
    required this.scrollX,
    required this.scrollY,
  });

  NativePointerPhase phase;
  double x;
  double y;

  /// 0 primary, 1 secondary, 2 middle.
  int button;

  /// Points to scroll; positive is right and down.
  double scrollX;
  double scrollY;
}

/// macOS: makes an extra display, captures only it with ScreenCaptureKit
/// and encodes it as real-time H.264 with VideoToolbox.
@HostApi()
abstract class DisplayCaptureHostApi {
  NativeDisplaySupport support();

  /// The screen Ferret's window is on, or the main one.
  NativeScreenPanel screen();

  /// Asks for Screen Recording, with the system's prompt the first time.
  /// Answers whether it is granted now.
  bool requestScreenRecording();

  /// Asks for Accessibility, which moving the pointer needs.
  bool requestInput();

  void openScreenRecordingSettings();

  /// Makes the display and starts sending it. Throws when it can't.
  @async
  void start(NativeDisplayOptions options);

  /// Stops sending and takes the display away.
  @async
  void stop();

  void requestKeyframe();

  void setBitrate(int bitrate);

  void pointer(NativeDisplayPointer event);
}

@FlutterApi()
abstract class DisplayCaptureFlutterApi {
  void onConfig(NativeStreamConfig config);

  void onFrame(NativeFrame frame);

  void onEnded(NativeCaptureEnd end);
}
