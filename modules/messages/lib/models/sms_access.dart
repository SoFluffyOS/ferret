/// What this phone lets Ferret do with texts and contacts.
class SmsAccess {
  const SmsAccess({
    required this.hasTelephony,
    required this.canRead,
    required this.canSend,
    required this.canReadContacts,
    this.blocked = false,
  });

  /// A device without SMS, such as a tablet or a computer.
  static const none = SmsAccess(
    hasTelephony: false,
    canRead: false,
    canSend: false,
    canReadContacts: false,
  );

  /// The device can send and receive SMS at all.
  final bool hasTelephony;
  final bool canRead;
  final bool canSend;
  final bool canReadContacts;

  /// SMS access was denied for good; only the app's settings can grant it.
  final bool blocked;
}
