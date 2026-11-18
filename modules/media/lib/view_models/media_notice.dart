import 'package:media/models/models.dart';

/// A short message under the controls after something didn't work.
sealed class MediaNotice {
  const MediaNotice(this.deviceName);

  final String deviceName;
}

final class CommandNotice extends MediaNotice {
  const CommandNotice(this.outcome, super.deviceName);

  final CommandOutcome outcome;
}

final class ContinueNotice extends MediaNotice {
  const ContinueNotice(this.reason, super.deviceName, {required this.appName});

  final ContinueFailure reason;
  final String appName;
}
