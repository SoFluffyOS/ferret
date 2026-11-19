import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  testWidgets('the logo is the bundled ferret, at the size asked', (
    tester,
  ) async {
    await tester.pumpWidget(
      FluffyTheme(
        data: FluffyThemeData.fallback(),
        child: const Center(child: FerretLogo(size: 64)),
      ),
    );

    final art = await rootBundle.loadString(
      'packages/feature_kit/assets/ferret_logo.svg',
    );
    expect(art, contains('plate-fill'));
    final size = tester.getSize(find.byType(FerretLogo));
    expect(size.width, closeTo(64, 0.01));
    expect(size.height, closeTo(64, 0.01));
  });
}
