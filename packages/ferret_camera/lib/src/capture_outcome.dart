/// How opening the camera ended.
enum CaptureOutcome {
  /// The person took a picture; it is in a temporary file.
  taken,

  /// The camera closed without a picture.
  cancelled,

  /// The system didn't let the app use the camera.
  noPermission,

  /// No camera here, no camera app, or no document scanner.
  unavailable,

  failed;

  /// [name] back as an outcome, or [failed] when it is unknown.
  static CaptureOutcome byNameOr(String? name) {
    for (final outcome in values) {
      if (outcome.name == name) {
        return outcome;
      }
    }

    return failed;
  }
}
