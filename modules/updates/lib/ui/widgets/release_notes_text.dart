import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A release's Markdown notes as plain lines: headings bold, list items
/// behind a hanging bullet, links and emphasis marks left out.
class ReleaseNotesText extends StatelessWidget {
  const ReleaseNotesText(this.notes, {super.key, required this.empty});

  final String notes;

  /// Shown when [notes] is empty.
  final String empty;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final body = typography.base2.copyWith(color: palette.text);
    final lines = linesOf(notes);
    if (lines.isEmpty) {
      return Text(empty, style: body.copyWith(color: palette.mutedText));
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0)
            switch (line.isHeading) {
              true => Spacing.v12,
              false => Spacing.v4,
            },
          switch ((line.isHeading, line.isBullet)) {
            (true, _) => Text(
              line.text,
              style: body.copyWith(fontWeight: .w600),
            ),
            (false, true) => Row(
              crossAxisAlignment: .start,
              children: [
                Text('•', style: body),
                Spacing.h8,
                Expanded(child: Text(line.text, style: body)),
              ],
            ),
            (false, false) => Text(line.text, style: body),
          },
        ],
      ],
    );
  }

  /// [notes] as lines to show, blank ones dropped.
  static List<({String text, bool isHeading, bool isBullet})> linesOf(
    String notes,
  ) => [
    for (final raw in notes.split('\n'))
      if (_plain(raw.trim()) case final line when line.text.isNotEmpty) line,
  ];

  static ({String text, bool isHeading, bool isBullet}) _plain(String line) {
    final heading = RegExp(r'^#{1,6}\s+').firstMatch(line);
    final bullet = RegExp(r'^[-*+]\s+').firstMatch(line);
    final text = switch ((heading, bullet)) {
      (final match?, _) => line.substring(match.end),
      (_, final match?) => line.substring(match.end),
      _ => line,
    };
    final clean = text
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'\*\*|__|`'), '');
    return (
      text: clean,
      isHeading: heading != null,
      isBullet: heading == null && bullet != null,
    );
  }
}
