import 'package:feature_kit/feature_kit.dart';
import 'package:find/ui/frames/frames.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Covers the app while this device rings, so "Found it" is one tap away.
class RingingPage extends StatelessWidget {
  const RingingPage({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(Spacing.d24),
        child: const RingingFrame(),
      ),
    ),
  );
}
