import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/notifications.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One of the app filters, with a title, a short explanation and a radio:
/// a row of a `GroupedCard`.
class FilterOptionRow extends StatelessWidget {
  const FilterOptionRow({
    super.key,
    required this.filter,
    required this.selected,
    required this.title,
    required this.detail,
    required this.onSelected,
  });

  final AppFilter filter;
  final AppFilter selected;
  final String title;
  final String detail;
  final ValueChanged<AppFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Tappable(
        behavior: .translucent,
        enableAnimation: false,
        onTap: () => onSelected(filter),
        child: GroupedRow(
          title: title,
          subtitle: detail,
          // The whole row takes the tap, so the radio's own 48 dp needn't
          // push the words aside.
          trailing: OutsetTouchTarget(
            child: RadioIcon<AppFilter>(
              value: filter,
              groupValue: selected,
              onChanged: onSelected,
            ),
          ),
        ),
      ),
    );
  }
}
