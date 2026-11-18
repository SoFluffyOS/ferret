/// How the last request to a phone went, for the device card's health chip.
class RoundTrip {
  const RoundTrip({required this.ok, required this.at});

  final bool ok;
  final DateTime at;
}
