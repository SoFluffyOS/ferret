import 'package:scripting/models/script_request.dart';

/// A request from Tasker or Shortcuts that didn't work, to say so on
/// screen: [error] is the command's error code, such as `not_connected`.
class ScriptRequestFailure {
  const ScriptRequestFailure({
    required this.request,
    required this.error,
    this.deviceName = '',
  });

  final ScriptRequest request;
  final String error;

  /// The device as Ferret calls it, or what the request named.
  final String deviceName;
}
