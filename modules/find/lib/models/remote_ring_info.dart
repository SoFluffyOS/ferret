import 'package:protocol/find.dart';

/// What another device last said about ringing, or that it didn't answer.
class RemoteRingInfo {
  const RemoteRingInfo.answered(RingInfo this.info) : failed = false;

  const RemoteRingInfo.failed() : info = null, failed = true;

  final RingInfo? info;
  final bool failed;
}
