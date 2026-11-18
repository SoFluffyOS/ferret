/// One receiver as settings show it: which, and whether it listens.
class ReceiverSwitch {
  const ReceiverSwitch({required this.receiverId, required this.on});

  final String receiverId;
  final bool on;

  @override
  bool operator ==(Object other) =>
      other is ReceiverSwitch &&
      other.receiverId == receiverId &&
      other.on == on;

  @override
  int get hashCode => Object.hash(receiverId, on);
}
