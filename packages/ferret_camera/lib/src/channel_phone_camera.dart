import 'package:ferret_camera/src/camera_abilities.dart';
import 'package:ferret_camera/src/camera_capture.dart';
import 'package:ferret_camera/src/phone_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android and iOS, through the plugin's channel.
class ChannelPhoneCamera implements PhoneCamera {
  static const _methods = MethodChannel('io.sofluffy.ferret_camera');

  @override
  bool get isSupported => true;

  @override
  bool get scansDocuments => defaultTargetPlatform == .iOS;

  @override
  Future<CameraAbilities> abilities() async =>
      CameraAbilities.fromMap(await _invoke<Object?>('abilities'));

  @override
  Future<CameraCapture> takePhoto() async =>
      CameraCapture.fromMap(await _invoke<Object?>('takePhoto'));

  @override
  Future<CameraCapture> scanDocument() async =>
      CameraCapture.fromMap(await _invoke<Object?>('scanDocument'));

  static Future<T?> _invoke<T>(String method) async {
    try {
      return await _methods.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
