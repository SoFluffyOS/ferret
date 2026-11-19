import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Ferret's own icon, the ferret on its sable plate, for the places the app
/// shows itself (Home's welcome). Rendered from `branding/`. Decorative:
/// the text next to it names the app.
class FerretLogo extends StatelessWidget {
  const FerretLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ImageView(
        'assets/ferret_logo.svg',
        size: size,
        fit: .contain,
        assetPackage: 'feature_kit',
      ),
    );
  }
}
