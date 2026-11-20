# ferret_mirroring

Captures an Android screen as H.264 (or JPEG pictures) and shows it on a computer.

| Platform | What | How |
|---|---|---|
| Android | Capture | MediaProjection (the system prompt every time) → VirtualDisplay → MediaCodec H.264, inside a `mediaProjection` foreground service with an ongoing notice. JPEG through an ImageReader as the fallback |
| macOS | Decode | VideoToolbox `VTDecompressionSession` → `CVPixelBuffer` → Flutter texture, through `sofluffy_texture`. Full screen for a normal window |
| Windows, Linux, iOS | Decode | JPEG only, with Flutter's own image codecs (`JpegMirrorDecoder`). No native code |
| macOS | Extra display | `DisplayCapture`: a `CGVirtualDisplay` sized to the other device's screen → ScreenCaptureKit (that display only) → VideoToolbox real-time H.264, and the other device's pointer posted onto it. Needs Screen Recording, and Accessibility for the pointer |

```dart
final capture = ScreenCapture.current();
if (await capture.requestConsent(texts, const Duration(seconds: 60)) == .granted) {
  capture.events.listen((event) { /* CaptureConfigured, CaptureFrame, CaptureEnded */ });
  await capture.start(const CaptureOptions(codec: .h264, maxLongSide: 1920, maxShortSide: 1080, fps: 60, bitrate: 4000000));
}

final decoder = MirrorDecoder.current();
await decoder.configure(config);
decoder.decode(frame); // draw decoder.picture
```

The consent is never kept: every capture starts with Android's own prompt.

## Credits

The extra display on macOS borrows from [OpenDisplay](https://github.com/peetzweg/opendisplay) (GPL-3.0): the private `CGVirtualDisplay` interface and its setup (first published by Khaos Tian in VirtualDisplayExp), the capture and the encoder settings. Each file that does says so at its top.

Regenerate the platform channel with `fvm dart run pigeon --input pigeon/messages.dart`.
