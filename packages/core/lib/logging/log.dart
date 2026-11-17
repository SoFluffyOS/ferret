import 'dart:async';

/// How serious a log line is.
enum LogLevel { debug, info, warning, error }

/// One line of the log.
class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    required this.time,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final DateTime time;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('[${level.name}] $message');
    if (error case final error?) {
      buffer.write(': $error');
    }

    return buffer.toString();
  }
}

/// Where log lines go. The default writes to the console; apps can add a file
/// sink. Nothing is ever sent off the device.
abstract final class Log {
  static final StreamController<LogRecord> _records = .broadcast(sync: true);
  static LogLevel minimum = .debug;
  static bool printToConsole = true;

  /// Every record written, for file sinks and in-app log viewers.
  static Stream<LogRecord> get records => _records.stream;

  static void write(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimum.index) {
      return;
    }

    final record = LogRecord(
      level: level,
      message: message,
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
    if (printToConsole) {
      // ignore: avoid_print
      print(record);
    }

    _records.add(record);
  }
}

/// Writes an info line to the log.
void printLog(String message) => Log.write(.info, message);

/// Writes a debug line to the log.
void printDebug(String message) => Log.write(.debug, message);

/// Writes a warning to the log.
void printWarning(String message, [Object? error]) =>
    Log.write(.warning, message, error: error);

/// Writes an error, with its stack trace when there is one.
void printError(String message, [Object? error, StackTrace? stackTrace]) =>
    Log.write(.error, message, error: error, stackTrace: stackTrace);
