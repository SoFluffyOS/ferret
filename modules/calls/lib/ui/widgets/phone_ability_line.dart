import 'package:calls/ui/widgets/status_line.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneAbilityLine extends StatelessWidget {
  const PhoneAbilityLine({
    super.key,
    required this.text,
    required this.allowed,
  });

  final String text;
  final bool allowed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Spacing.d4),
    child: StatusLine(
      text: text,
      tone: switch (allowed) {
        true => .good,
        false => .neutral,
      },
    ),
  );
}
