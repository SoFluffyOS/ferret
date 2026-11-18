/// The kind of device an endpoint says it is. Phones pick an icon from it.
enum QuickShareDeviceKind {
  unknown(0),
  phone(1),
  tablet(2),
  laptop(3),
  car(4),
  foldable(5),
  headset(6);

  const QuickShareDeviceKind(this.code);

  /// The three bits the endpoint info carries.
  final int code;

  static QuickShareDeviceKind fromCode(int code) {
    for (final kind in values) {
      if (kind.code == code) {
        return kind;
      }
    }

    return unknown;
  }
}
