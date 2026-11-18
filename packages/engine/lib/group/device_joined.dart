import 'package:engine/trust/trust.dart';

/// A device that joined the user's devices through another one of them,
/// without being paired here.
class DeviceJoined {
  const DeviceJoined({required this.device, required this.introducer});

  final TrustedDevice device;

  /// The paired device that vouched for it.
  final TrustedDevice introducer;
}
