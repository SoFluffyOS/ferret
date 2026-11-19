import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Short copy with `**bold**` and `` `code` `` marks, so the landing's words
/// read like the README's.
List<Component> richText(String source) {
  final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
  final parts = <Component>[];
  var start = 0;

  for (final match in pattern.allMatches(source)) {
    if (match.start > start) {
      parts.add(Component.text(source.substring(start, match.start)));
    }

    if (match.group(1) case final bold?) {
      parts.add(strong([Component.text(bold)]));
    }

    if (match.group(2) case final snippet?) {
      parts.add(code([Component.text(snippet)]));
    }

    start = match.end;
  }

  if (start < source.length) {
    parts.add(Component.text(source.substring(start)));
  }

  return parts;
}
