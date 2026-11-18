/// Who decided that a device is no longer one of the user's.
enum ForgottenBy {
  /// The user removed it on this device only. Stays here.
  here,

  /// The user removed it from all their devices. Passed on to them.
  everywhere,

  /// The device dropped this one. Stays here, and is lifted when the user
  /// pairs anything by hand again.
  them,
}

/// A device that is no longer trusted, remembered so another of the user's
/// devices that missed it doesn't bring it back.
class ForgottenDevice {
  const ForgottenDevice({required this.id, required this.at, required this.by});

  factory ForgottenDevice.fromJson(Map<String, dynamic> json) =>
      ForgottenDevice(
        id: json['id'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
        by: ForgottenBy.values.asNameMap()[json['by']] ?? .here,
      );

  final String id;
  final DateTime at;
  final ForgottenBy by;

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'by': by.name,
  };
}
