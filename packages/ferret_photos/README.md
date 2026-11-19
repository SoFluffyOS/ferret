# ferret_photos

Reads a phone's recent photos and screenshots, read only. Part of [Ferret](../../README.md), usable on its own.

```dart
final library = PhotoLibrary.current();
if (!(await library.access()).canRead) {
  await library.requestAccess(); // only while the app is on screen
}

final page = await library.list(limit: 60); // newest first
final jpeg = await library.thumbnail(page.entries.first.id, maxPx: 256);
final path = await library.export(page.entries.first.id); // a temporary copy
library.newScreenshots.listen((shot) => print(shot.name));
```

| Platform | How |
|---|---|
| Android | MediaStore. `READ_MEDIA_IMAGES`/`VIDEO` on 13+, `READ_EXTERNAL_STORAGE` before. Android 14's "Selected photos" reads as `limited`; asking again lets the person pick more. New screenshots come from a `ContentObserver` while someone listens |
| iOS | PhotoKit, full or limited library. Asking again while limited opens the picker. New screenshots come from `PHPhotoLibraryChangeObserver`, only while the app runs |
| Computers | `UnsupportedPhotoLibrary`: nothing to read |

Nothing here deletes or changes a photo. Names and paths are never logged.

The iOS app needs `NSPhotoLibraryUsageDescription` in its `Info.plist`.
