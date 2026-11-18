/// What a LocalSend device says about itself, shown before accepting from
/// it. None of it is proven: any device on the network can claim any name.
class LocalSendOrigin {
  const LocalSendOrigin({
    required this.fingerprint,
    required this.address,
    this.deviceModel = '',
  });

  /// The model the device reports, such as "iPhone", or empty.
  final String deviceModel;

  /// The device's LocalSend fingerprint.
  final String fingerprint;

  /// The device's address on the network.
  final String address;
}
