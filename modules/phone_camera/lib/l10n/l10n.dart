import 'package:flutter/widgets.dart';
import 'package:phone_camera/l10n/generated/camera_localizations.dart';

export 'package:phone_camera/l10n/generated/camera_localizations.dart';

extension CameraL10n on BuildContext {
  CameraLocalizations get cameraL10n => CameraLocalizations.of(this);
}
