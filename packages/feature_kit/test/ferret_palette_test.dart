import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

const _ferretBlue = Color(0xFF0A66D6);

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color first, Color second) {
  final lighter = [
    first.computeLuminance(),
    second.computeLuminance(),
  ]..sort();
  return (lighter.last + 0.05) / (lighter.first + 0.05);
}

Future<FerretPalette> _palette(
  WidgetTester tester,
  Brightness brightness,
) async {
  late FerretPalette palette;
  final fallback = FluffyThemeData.fallback(brightness: brightness);
  await tester.pumpWidget(
    FluffyTheme(
      data: fallback.copyWith(
        colors: fallback.colors.copyWith(primary: _ferretBlue),
      ),
      child: Builder(
        builder: (context) {
          palette = context.palette;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return palette;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'every text colour reads at 4.5:1 on cards and pages, ${brightness.name}',
      (tester) async {
        final palette = await _palette(tester, brightness);
        final texts = {
          'text': palette.text,
          'mutedText': palette.mutedText,
          'link': palette.link,
          'success': palette.success,
          'warning': palette.warning,
          'danger': palette.danger,
        };

        for (final MapEntry(key: name, value: color) in texts.entries) {
          for (final fill in [palette.surface, palette.background]) {
            expect(
              _contrast(color, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$name on $fill',
            );
          }
        }
      },
    );
  }
}
