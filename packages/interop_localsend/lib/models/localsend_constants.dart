/// Defaults from the LocalSend protocol, section 1.
abstract final class LocalSendDefaults {
  static const port = 53317;
  static const multicastGroup = '224.0.0.167';

  /// The protocol version this package speaks, as `major.minor`.
  static const version = '2.0';

  static const apiPath = '/api/localsend/v2';
  static const https = 'https';
  static const http = 'http';
}
