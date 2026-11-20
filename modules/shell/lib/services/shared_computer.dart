import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';

/// Tells this Ferret apart from Ferret in other accounts on the same
/// computer, such as a family PC where each person has their own login.
///
/// Once another account's Ferret is heard, this computer counts as shared
/// until the person says only they use it, and unless the person picked a
/// name, it goes by the account too: "Family PC (Anna)" instead of a second
/// "Family PC".
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

  /// [computerName] as this account goes by on the network. A name that
  /// already says whose it is, such as "Simon's MacBook Pro" for `simon`,
  /// stays as it is.
  String nameFor(String computerName) {
    final account = accountName;
    if (!isShared || hasChosenName || account == null) {
      return computerName;
    }

    if (computerName.toLowerCase().contains(account.toLowerCase())) {
      return computerName;
    }

    return '$computerName ($account)';
  }

  /// [name] without the account [nameFor] added to it.
  String plainName(String name) {
    final suffix = ' ($accountName)';
    if (accountName == null || !name.endsWith(suffix)) {
      return name;
    }

    return name.substring(0, name.length - suffix.length);
  }

  /// The person says only they use this computer: it stops counting as
  /// shared, so previews follow the usual default again, and the account
  /// leaves the name unless the person picked it. Choices made for each
  /// device stay. Hearing Ferret in another account marks it shared again.
  Future<void> onlyMe(FerretEngine engine) async {
    await settings.set(sharedKey, false);
    if (hasChosenName) {
      return;
    }

    await engine.rename(plainName(engine.device.name), remember: false);
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
