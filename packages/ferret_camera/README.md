# ferret_camera

Takes one photo with the phone's own camera, or scans a document on an iPhone, and hands back a file. Part of [Ferret](../../README.md), usable on its own.

```dart
final camera = PhoneCamera.current();
final result = await camera.takePhoto(); // only while the app is on screen
if (result.outcome == CaptureOutcome.taken) {
  send(result.path); // a temporary JPEG: delete it once sent
}
```

| Platform | How |
|---|---|
| Android | The system camera intent (`ACTION_IMAGE_CAPTURE`) into a `FileProvider` file in the app's cache. No camera code of its own, no Google libraries. If the app also declares `CAMERA` (to scan a QR code, say), it is asked for first, since Android refuses the intent otherwise. No document scanner |
| iOS | `UIImagePickerController` for a photo, VisionKit's `VNDocumentCameraViewController` for a scan (a JPEG for one page, a PDF for several) |
| Computers | `UnsupportedPhoneCamera`: nothing to open |

Photos come back as JPEGs turned the right way up, at most 4096 px long on Android, with no EXIF, so no location. The person always sees the camera and presses the shutter: nothing is ever captured on its own.

The iOS app needs `NSCameraUsageDescription` in its `Info.plist`.
