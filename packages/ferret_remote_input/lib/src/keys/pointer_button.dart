enum PointerButton {
  left(0),
  right(1),
  middle(2);

  const PointerButton(this.code);

  /// The button's number in a native event.
  final int code;
}
