import 'package:feature_kit/feature_kit.dart';
import 'package:remote_input/l10n/generated/remote_input_localizations.dart';
import 'package:remote_input/models/models.dart';

/// The question a device asks this computer's owner, worded for what it
/// asks: control, or locking the screen.
extension ConsentTexts on RemoteInputLocalizations {
  String consentTitleOf(ConsentRequest request, HostKind host) =>
      switch (request.kind) {
        .control => consentTitle(request.deviceName, ThisComputer.here),
        .lock => lockConsentTitle(request.deviceName, host.name),
      };

  String consentBodyOf(ConsentRequest request) => switch (request.kind) {
    .control => consentBody(request.deviceName),
    .lock => lockConsentBody(request.deviceName),
  };
}
