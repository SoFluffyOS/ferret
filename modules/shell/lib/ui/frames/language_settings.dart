import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings → Advanced: the language Ferret shows, the system's by default.
/// Each language is named in itself.
class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ShellScope.of(context).featureContext.engine.settings;
    final chosen = chosenLocale(context);
    final l10n = context.shellL10n;
    final palette = context.palette;

    Widget row(String title, Locale? locale) {
      final isChosen = chosen?.languageCode == locale?.languageCode;
      return Semantics(
        selected: isChosen,
        child: GroupedRow(
          title: title,
          onTap: () => unawaited(LanguagePreference.choose(settings, locale)),
          trailing: switch (isChosen) {
            true => Icon(
              LucideIcons.check,
              size: Spacing.d16,
              color: palette.accent,
            ),
            false => null,
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsLanguage),
        GroupedCard(
          children: [
            row(l10n.settingsLanguageSystem, null),
            for (final locale in ShellLocalizations.supportedLocales)
              row(LanguagePreference.endonymOf(locale), locale),
          ],
        ),
        // Phones have no menus or tray, and Android switches its own
        // notices right away.
        if (_hasMenus)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: PageInsets.row,
              end: PageInsets.row,
              top: Spacing.d8,
            ),
            child: Text(
              l10n.settingsLanguageNote,
              style: context.fluffyTheme.typography.caption1.copyWith(
                color: palette.mutedText,
              ),
            ),
          ),
      ],
    );
  }

  static bool get _hasMenus => switch (defaultTargetPlatform) {
    .macOS || .windows || .linux => true,
    _ => false,
  };
}
