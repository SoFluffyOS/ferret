/// What kind of device a LocalSend member is. Only used to pick an icon.
enum LocalSendDeviceType {
  mobile,
  desktop,
  web,
  headless,
  server;

  /// Unknown and missing values fall back to [desktop], as the protocol
  /// asks.
  static LocalSendDeviceType parse(Object? value) {
    for (final type in values) {
      if (type.name == value) {
        return type;
      }
    }

    return desktop;
  }
}
