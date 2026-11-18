import 'package:protocol/calls.dart';

/// What this device knows about calls on one connected phone.
class PhoneLink {
  const PhoneLink({this.status, this.failed = false, this.lastRoundTrip});

  /// What the phone last said it can do, or null when it never answered.
  final CallsStatus? status;

  /// The last request to the phone got no answer.
  final bool failed;

  /// When the phone last answered a request.
  final DateTime? lastRoundTrip;

  PhoneLink answered(DateTime at, {CallsStatus? status}) => PhoneLink(
    status: status ?? this.status,
    lastRoundTrip: at,
  );

  PhoneLink unanswered() =>
      PhoneLink(status: status, failed: true, lastRoundTrip: lastRoundTrip);
}
