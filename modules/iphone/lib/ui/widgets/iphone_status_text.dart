import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class IphoneStatusText extends StatelessWidget {
  const IphoneStatusText({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.fluffyTheme.typography.body2.copyWith(color: color),
  );
}
