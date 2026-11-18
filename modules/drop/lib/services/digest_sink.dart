import 'package:crypto/crypto.dart';

/// Collects the one digest a chunked SHA-256 conversion produces.
class DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value {
    if (_value case final digest?) {
      return digest;
    }

    throw StateError('The hash is not closed yet');
  }

  @override
  void add(Digest data) => _value = data;

  @override
  void close() {}
}
