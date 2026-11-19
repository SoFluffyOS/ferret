/// Marks a notice or an Activity line as private to the person who owns the
/// paired device [deviceId], such as a text, a notification or a caller.
///
/// On a computer several people use, the shell shows [cover] instead when
/// that device's previews are off here, and hides notices while the screen
/// is locked or another account is in front.
class PrivateContent {
  const PrivateContent(this.deviceId, {required this.cover});

  final String deviceId;

  /// What may show in its place, such as "New text on Pixel 7". Never the
  /// content itself: no names, numbers or words from it.
  final String cover;
}
