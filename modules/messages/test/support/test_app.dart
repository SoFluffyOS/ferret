import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme, localizations and navigator the feature's
/// widgets expect. [scroll] puts it in a list, as the shell does with cards
/// and settings sections.
Widget testApp(Widget child, {bool scroll = true}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    MessagesLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: MessagesLocalizations.supportedLocales,
  builder: (context, _) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => switch (scroll) {
            true => ListView(children: [child]),
            false => child,
          },
        ),
      ),
    ),
  ),
);

/// A 1×1 PNG, small enough to inline and real enough to decode.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
