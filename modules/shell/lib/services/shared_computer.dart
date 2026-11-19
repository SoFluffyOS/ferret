import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';

/// Tells this Ferret apart from Ferret in other accounts on the same
/// computer, such as a family PC where each person has their own login.
///
/// Once another account's Ferret is heard, this computer counts as shared
/// for good, and unless the person picked a name, it goes by the account
/// too: "Family PC (Anna)" instead of a second "Family PC".
class SharedComputer {
  SharedComputer(this.settings, {Map<String, String>? environment})
    : _environment = environment ?? const {};

  /// Setting: Ferret in another account on this computer was heard.
  static const sharedKey = 'device.shared_computer';

  /// The name the person chose, which always wins.
  static const nameKey = 'device.name';

  final SettingsStore settings;
  final Map<String, String> _environment;

  bool get isShared => settings.get<bool>(sharedKey) ?? false;

  /// Whether the person named this device themselves.
  bool get hasChosenName => switch (settings.get<String>(nameKey)) {
    final name? => name.trim().isNotEmpty,
    null => false,
  };

  /// The account's login name with a capital first letter, such as "Anna"
  /// for `anna`. Null when the system doesn't say.
  String? get accountName {
    final login = [
      _environment['USER'],
      _environment['USERNAME'],
      _environment['LOGNAME'],
    ].nonNulls.map((name) => name.trim()).where((name) => name.isNotEmpty);
    final first = login.firstOrNull;
    if (first == null) {
      return null;
    }

    return '${first[0].toUpperCase()}${first.substring(1)}';
  }

  /// [computerName] as this account goes by on the network.
  String nameFor(String computerName) {
    final account = accountName;
    if (!isShared || hasChosenName || account == null) {
      return computerName;
    }

    return '$computerName ($account)';
  }

  /// Marks the computer shared and renames this device the first time
  /// [engine] hears Ferret in another account.
  StreamSubscription<void> follow(
    FerretEngine engine, {
    required String computerName,
  }) => engine.otherAccountsChanges.listen(
    (_) => unawaited(_onOtherAccount(engine, computerName)),
  );

  Future<void> _onOtherAccount(FerretEngine engine, String computerName) async {
    if (!isShared) {
      await settings.set(sharedKey, true);
    }

    if (hasChosenName) {
      return;
    }

    await engine.rename(nameFor(computerName), remember: false);
  }
}
