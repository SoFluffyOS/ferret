import 'package:feature_kit/feature_kit.dart';
import 'package:shell/l10n/generated/shell_localizations.dart';
import 'package:shell/models/settings_row.dart';

extension SettingsValues on ShellLocalizations {
  /// A Settings row's state in a few words. One part speaks for itself;
  /// several are counted, except other apps, which are named.
  String settingsRowValue(SettingsRow row) {
    final (sections, switchable, on) = (row.sections, row.switchable, row.on);
    if (sections case [final only]) {
      return switch ((only.summary, only.isOn)) {
        ('', true) => settingsOn,
        ('', false) => settingsOff,
        (final summary, _) => summary,
      };
    }

    if (switchable.isEmpty) {
      return '';
    }

    if (on.isEmpty) {
      return settingsOff;
    }

    if (row.group == .otherApps) {
      return settingsNamedOn(
        ListText.join(on.map((part) => part.title), localeName: localeName),
      );
    }

    if (on.length == switchable.length) {
      return settingsOn;
    }

    return settingsCountOn(on.length, switchable.length);
  }
}
