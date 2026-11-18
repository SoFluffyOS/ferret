import 'dart:async';

import 'package:handoff/models/models.dart';
import 'package:handoff/services/browser/browser_channel.dart';

/// What the bridge knows about one connected extension.
class BrowserConnection {
  BrowserConnection(this.channel, {required this.browser});

  final BrowserChannel channel;

  /// The browser's name, from its hello (or the origin's family).
  String browser;

  /// Set once the extension said hello.
  bool greeted = false;

  /// Set once the extension proved it was paired, by token or by pairing.
  BrowserClient? client;

  /// Whether one of the browser's windows has focus, as it last said.
  bool focused = false;
  DateTime focusChangedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Malformed messages so far; too many closes the connection.
  int strikes = 0;
  bool closed = false;
  Timer? unpairedTimer;
  String suggestionsKey = '';

  bool get isPaired => client != null;
}
