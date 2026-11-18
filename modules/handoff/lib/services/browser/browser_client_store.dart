import 'package:core/core.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/browser/browser_token.dart';
import 'package:handoff/services/handoff_settings.dart';

/// The browser extensions the user allowed, kept in Handoff's settings.
class BrowserClientStore {
  BrowserClientStore(this._settings);

  /// More than anyone has browsers; stops a runaway from growing the file.
  static const maxClients = 16;

  final SettingsStore _settings;

  List<BrowserClient> get clients => [
    for (final entry
        in _settings.get<List<Object?>>(HandoffSettings.browserClients) ??
            const <Object?>[])
      ?BrowserClient.fromJson(entry),
  ];

  /// The client that [token] belongs to, when it comes from the same
  /// [origin] it was paired from.
  BrowserClient? find({required String token, required String origin}) {
    for (final client in clients) {
      if (client.origin == origin &&
          BrowserToken.matches(token, client.tokenHash)) {
        return client;
      }
    }

    return null;
  }

  BrowserClient? byId(String id) {
    for (final client in clients) {
      if (client.id == id) {
        return client;
      }
    }

    return null;
  }

  /// Keeps [client], replacing an older pairing from the same origin.
  Future<void> add(BrowserClient client) async {
    final others = [
      for (final existing in clients)
        if (existing.origin != client.origin) existing,
    ];
    final kept = [client, ...others].take(maxClients);
    await _save(kept);
  }

  Future<bool> remove(String id) async {
    final before = clients;
    final kept = [
      for (final client in before)
        if (client.id != id) client,
    ];
    if (kept.length == before.length) {
      return false;
    }

    await _save(kept);
    return true;
  }

  Future<void> _save(Iterable<BrowserClient> clients) => _settings.set(
    HandoffSettings.browserClients,
    [for (final client in clients) client.toJson()],
  );
}
