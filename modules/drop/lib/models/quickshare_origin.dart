/// What is known about a Quick Share sender, shown before accepting from
/// it. Its name is a claim; the PIN is what ties the offer to a phone.
class QuickShareOrigin {
  const QuickShareOrigin({required this.pin, required this.address});

  /// The 4-digit PIN the sender's screen shows for this transfer.
  final String pin;

  /// The device's address on the network.
  final String address;
}
