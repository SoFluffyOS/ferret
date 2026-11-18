import 'dart:io';

import 'package:interop_localsend/models/models.dart';

/// Stops one request from this side, such as when someone taps Cancel
/// while the receiver is still deciding.
class LocalSendAbort {
  HttpClientRequest? _request;
  bool _aborted = false;

  bool get isAborted => _aborted;

  /// Stops the request. It then fails with [LocalSendFailure.cancelled].
  void abort() {
    _aborted = true;
    _request?.abort(const LocalSendException(.cancelled));
  }

  /// Ties this to [request], stopping it at once when [abort] already ran.
  void attach(HttpClientRequest request) {
    _request = request;
    if (_aborted) {
      request.abort(const LocalSendException(.cancelled));
    }
  }
}
