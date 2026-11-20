import 'package:feature_kit/widgets/grouped_row.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting that is on or off: what it does, a line of detail, a switch.
/// A row of a `GroupedCard`.
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.body,
    this.tag,
    this.badge,
  });

  final String title;

  /// A line that says what the setting does.
  final String? body;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// A word next to the title, such as "Experimental".
  final String? tag;

  /// A small widget next to the title, such as a `BetaTag`.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GroupedRow(
        title: title,
        subtitle: body,
        tag: tag,
        badge: badge,
        trailing: SwitchToggle(value: value, onChanged: onChanged),
      ),
    );
  }
}
