import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line of [text] that, when too long, keeps its start and its end
/// and drops the middle, as Finder does with a file name: both
/// "PXL_2026…export.jpg" and its extension stay readable. Cut text shows
/// in full in a tooltip.
class MiddleEllipsisText extends StatefulWidget {
  const MiddleEllipsisText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static const _ellipsis = '…';

  /// The family to measure with where a style names none. Screenshot
  /// tests draw with a font of their own that the system default can't
  /// be swapped for, so they name it here.
  @visibleForTesting
  static String? debugMeasureFontFamily;

  @override
  State<MiddleEllipsisText> createState() => _MiddleEllipsisTextState();

  /// [text] as it fits in [maxWidth] on one line: itself, or its start and
  /// end around an ellipsis, with a little more of the start kept.
  static String fit(
    String text, {
    required double maxWidth,
    required TextStyle style,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = .ltr,
  }) {
    final measured = switch ((style.fontFamily, debugMeasureFontFamily)) {
      (null, final family?) => style.copyWith(
        fontFamily: family,
        fontVariations: [
          FontVariation.weight((style.fontWeight ?? .normal).value.toDouble()),
        ],
      ),
      _ => style,
    };
    final painter = TextPainter(
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    );
    bool fits(String candidate) {
      painter
        ..text = TextSpan(text: candidate, style: measured)
        ..layout();
      return painter.width <= maxWidth;
    }

    try {
      if (!maxWidth.isFinite || fits(text)) {
        return text;
      }

      final characters = text.characters.toList();
      String cut(int kept) {
        final tail = kept ~/ 2;
        final head = kept - tail;
        return [
          ...characters.take(head),
          _ellipsis,
          ...characters.skip(characters.length - tail),
        ].join();
      }

      var low = 0;
      var high = characters.length - 1;
      while (low < high) {
        final middle = (low + high + 1) ~/ 2;
        if (fits(cut(middle))) {
          low = middle;
          continue;
        }

        high = middle - 1;
      }

      return cut(low);
    } finally {
      painter.dispose();
    }
  }
}

class _MiddleEllipsisTextState extends State<MiddleEllipsisText> {
  @override
  void initState() {
    super.initState();
    // Fonts arrive from Google Fonts while the app runs: what fitted in
    // the fallback font is measured again in the real one.
    PaintingBinding.instance.systemFonts.addListener(_onFontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    super.dispose();
  }

  void _onFontsChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = MiddleEllipsisText.fit(
          widget.text,
          maxWidth: constraints.maxWidth,
          style: style,
          textScaler: textScaler,
          textDirection: direction,
        );
        final line = Text(
          shown,
          style: style,
          maxLines: 1,
          softWrap: false,
          overflow: .clip,
          semanticsLabel: widget.text,
        );
        if (shown == widget.text) {
          return line;
        }

        return FluffyTooltip(message: widget.text, child: line);
      },
    );
  }
}
