/// Why a LocalSend request didn't work, from the protocol's error tables
/// and from the network.
enum LocalSendFailure {
  /// 400: the receiver couldn't read the request.
  invalidRequest,

  /// 401: the receiver wants a PIN, or the PIN was wrong.
  pinRequired,

  /// 403: the receiver said no, or the token or address didn't match.
  rejected,

  /// 409: the receiver is busy with another transfer.
  busy,

  /// 422: the data didn't match the size or SHA-256 that was announced.
  checksum,

  /// 429: too many attempts.
  tooManyRequests,

  /// 500: the receiver failed, such as a full disk.
  receiverError,

  /// No answer: the device is gone, off, or on another network.
  unreachable,

  /// The device showed a different certificate than it announced.
  untrusted,

  /// This side stopped the request.
  cancelled,

  /// Anything else the protocol doesn't describe.
  unexpected;

  static LocalSendFailure fromStatus(int status) => switch (status) {
    400 => invalidRequest,
    401 => pinRequired,
    403 => rejected,
    409 => busy,
    422 => checksum,
    429 => tooManyRequests,
    500 => receiverError,
    _ => unexpected,
  };
}
