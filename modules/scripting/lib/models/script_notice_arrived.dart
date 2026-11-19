/// A notice a script on another device asked this one to show.
class ScriptNoticeArrived {
  const ScriptNoticeArrived({
    required this.deviceId,
    required this.deviceName,
    required this.title,
    required this.body,
  });

  final String deviceId;
  final String deviceName;
  final String title;
  final String body;
}
