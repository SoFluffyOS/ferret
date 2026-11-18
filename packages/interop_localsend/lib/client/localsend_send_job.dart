import 'dart:async';

import 'package:interop_localsend/client/localsend_abort.dart';
import 'package:interop_localsend/client/localsend_client.dart';
import 'package:interop_localsend/client/localsend_outgoing_file.dart';
import 'package:interop_localsend/models/models.dart';

/// Sends a set of files to one LocalSend member: offers them, waits for
/// the answer, then uploads each file the receiver wants, one at a time.
class LocalSendSendJob {
  LocalSendSendJob({
    required this.client,
    required this.peer,
    required this.self,
    required this.files,
    this.pin,
  });

  final LocalSendClient client;
  final LocalSendPeer peer;
  final LocalSendInfo self;
  final List<LocalSendOutgoingFile> files;

  /// For receivers protected by a PIN.
  final String? pin;

  LocalSendAbort _abort = LocalSendAbort();
  String? _sessionId;
  bool _cancelled = false;
  bool _offered = false;

  /// Runs the transfer. Returns the ids of the files the receiver took,
  /// which is empty when it needed no upload. Throws a
  /// [LocalSendException] that says why it stopped.
  ///
  /// [onAccepted] fires once the receiver said yes; [onProgress] gets the
  /// bytes sent so far, over all files.
  Future<Set<String>> run({
    void Function()? onAccepted,
    void Function(int sentBytes)? onProgress,
  }) async {
    final request = PrepareUploadRequest(
      info: self,
      files: {for (final outgoing in files) outgoing.file.id: outgoing.file},
    );
    _offered = true;
    final response = await client.prepareUpload(
      peer,
      request,
      pin: pin,
      abort: _abort,
    );
    _offered = false;
    _throwIfCancelled();
    if (response == null) {
      return const {};
    }

    _sessionId = response.sessionId;
    onAccepted?.call();

    var sentBefore = 0;
    for (final outgoing in files) {
      final token = response.files[outgoing.file.id];
      if (token == null) {
        continue;
      }

      _throwIfCancelled();
      _abort = LocalSendAbort();
      var sent = sentBefore;
      await client.upload(
        peer,
        sessionId: response.sessionId,
        fileId: outgoing.file.id,
        token: token,
        data: outgoing.open().map((chunk) {
          sent += chunk.length;
          onProgress?.call(sent);
          return chunk;
        }),
        length: outgoing.file.size,
        abort: _abort,
      );
      sentBefore += outgoing.file.size;
      onProgress?.call(sentBefore);
    }

    _throwIfCancelled();
    return response.files.keys.toSet();
  }

  /// Stops the transfer and tells the receiver.
  Future<void> cancel() async {
    if (_cancelled) {
      return;
    }

    _cancelled = true;
    _abort.abort();
    if (_sessionId == null && !_offered) {
      return;
    }

    try {
      await client.cancel(peer, sessionId: _sessionId);
    } on LocalSendException {
      return;
    }
  }

  void _throwIfCancelled() {
    if (_cancelled) {
      throw const LocalSendException(.cancelled);
    }
  }
}
