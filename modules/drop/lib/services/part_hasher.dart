import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drop/services/digest_sink.dart';

/// SHA-256 of each part file worked out while its chunks arrive, in one
/// background isolate per transfer. A big file then needs no second read
/// before it's saved, and a folder of small files no isolate per file.
///
/// It only follows bytes that arrive in order from the start; when a part
/// is cut back or skipped ahead, [digest] says so with null and the caller
/// hashes the file on disk instead.
class PartHasher {
  final Map<int, int> _hashed = {};
  final Map<int, Completer<List<int>?>> _answers = {};
  final List<Object?> _waiting = [];
  ReceivePort? _replies;
  SendPort? _commands;
  Isolate? _isolate;
  bool _starting = false;
  bool _disposed = false;
  int _nextAnswer = 0;

  /// [bytes] were written to part [index] at [offset]. Bytes at 0 start
  /// the part over.
  void add(int index, int offset, List<int> bytes) {
    if (_disposed) {
      return;
    }

    final hashed = _hashed[index];
    if (offset == 0 && hashed != null && hashed != 0) {
      _drop(index);
    } else if (offset != 0 && hashed != offset) {
      forget(index);
      return;
    }

    _hashed[index] = offset + bytes.length;
    final data = switch (bytes) {
      final Uint8List list => list,
      _ => Uint8List.fromList(bytes),
    };
    _send([
      'add',
      index,
      TransferableTypedData.fromList([data]),
    ]);
  }

  /// Part [index] no longer matches what was hashed, such as after it was
  /// cut back for a resume. It is hashed from disk unless it starts over.
  void forget(int index) {
    _drop(index);
    _hashed[index] = _broken;
  }

  /// The SHA-256 of part [index] when exactly its first [length] bytes were
  /// hashed, or null when the file on disk has to be read instead.
  Future<List<int>?> digest(int index, int length) {
    final hashed = _hashed[index];
    if (_disposed || hashed == null || hashed == _broken) {
      return Future.value();
    }

    if (hashed != length) {
      forget(index);
      return Future.value();
    }

    _hashed.remove(index);
    final id = _nextAnswer++;
    final answer = _answers[id] = Completer<List<int>?>();
    _send(['digest', index, id]);
    return answer.future;
  }

  static const _broken = -1;

  void _drop(int index) {
    final hashed = _hashed.remove(index);
    if (hashed != null && hashed != _broken) {
      _send(['forget', index]);
    }
  }

  void dispose() {
    _disposed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _replies?.close();
    _replies = null;
    _commands = null;
    _waiting.clear();
    for (final answer in _answers.values) {
      answer.complete(null);
    }

    _answers.clear();
  }

  void _send(Object? message) {
    if (_disposed) {
      return;
    }

    if (_commands case final commands?) {
      commands.send(message);
      return;
    }

    _waiting.add(message);
    unawaited(_start());
  }

  Future<void> _start() async {
    if (_starting || _commands != null) {
      return;
    }

    _starting = true;
    final replies = _replies = ReceivePort();
    final ready = Completer<SendPort>();
    replies.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
        return;
      }

      if (message case [final int id, final Uint8List? bytes]) {
        _answers.remove(id)?.complete(bytes);
      }
    });

    try {
      _isolate = await Isolate.spawn(_run, replies.sendPort);
      final commands = await ready.future;
      if (_disposed) {
        _isolate?.kill(priority: Isolate.immediate);
        return;
      }

      _commands = commands;
      for (final message in _waiting) {
        commands.send(message);
      }

      _waiting.clear();
    } on Object {
      dispose();
    } finally {
      _starting = false;
    }
  }

  static void _run(SendPort replies) {
    final commands = ReceivePort();
    final sinks = <int, ({ByteConversionSink sink, DigestSink digest})>{};
    replies.send(commands.sendPort);
    commands.listen((message) {
      switch (message) {
        case ['add', final int index, final TransferableTypedData data]:
          final entry = sinks.putIfAbsent(index, () {
            final digest = DigestSink();
            return (
              sink: sha256.startChunkedConversion(digest),
              digest: digest,
            );
          });
          entry.sink.add(data.materialize().asUint8List());
        case ['forget', final int index]:
          sinks.remove(index)?.sink.close();
        case ['digest', final int index, final int id]:
          final entry = sinks.remove(index);
          if (entry == null) {
            replies.send([id, null]);
            return;
          }

          entry.sink.close();
          replies.send([id, Uint8List.fromList(entry.digest.value.bytes)]);
      }
    });
  }
}
