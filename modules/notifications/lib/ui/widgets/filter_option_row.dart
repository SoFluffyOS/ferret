import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/notifications.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One of the app filters, with a title, a short explanation and a radio.
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
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return MergeSemantics(
      child: Tappable(
        behavior: .translucent,
        enableAnimation: false,
        onTap: () => onSelected(filter),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.d4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      title,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                    Spacing.vertical(Spacing.d2),
                    Text(
                      detail,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              RadioIcon<AppFilter>(
                value: filter,
                groupValue: selected,
                onChanged: onSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
