import 'package:feature_kit/widgets/focus_rings.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The design system's outlined (ghost) button that wears one ring at a
/// time: focused from the keyboard, its grey outline gives way to the
/// accent focus ring. Takes the same arguments as `Button`. In dark mode
/// it shows the surface under it inside its outline ([GhostFill]).
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.color,
    this.tooltip,
    this.enable = true,
    this.enableHover = true,
    this.titleExpand = ButtonTitleExpand.none,
    this.onPressed,
    this.child,
    this.semanticLabel,
    this.width,
    this.height,
    this.borderWidth,
    this.radius,
    this.padding,
    this.mainAxisSize,
    this.mainAxisAlignment,
    this.labelTextAlign,
  });

  final Function? onPressed;
  final String? label;
  final Widget? icon;
  final Widget? child;
  final Widget? trailingIcon;
  final Color? color;
  final bool enable;
  final bool enableHover;
  final ButtonTitleExpand titleExpand;
  final String? tooltip;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final double? borderWidth;
  final double? radius;
  final EdgeInsets? padding;
  final MainAxisSize? mainAxisSize;
  final MainAxisAlignment? mainAxisAlignment;
  final TextAlign? labelTextAlign;

  @override
  Widget build(BuildContext context) {
    final button = ButtonFocusRing(
      builder: (context, keyboardFocused) => Button(
        variant: .ghost,
        label: label,
        icon: icon,
        trailingIcon: trailingIcon,
        color: color,
        tooltip: tooltip,
        enable: enable,
        enableHover: enableHover,
        titleExpand: titleExpand,
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        width: width,
        height: height,
        borderWidth: switch (keyboardFocused) {
          true => 0,
          false => borderWidth,
        },
        radius: radius,
        padding: padding,
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        labelTextAlign: labelTextAlign,
        child: child,
      ),
    );
    return GhostFill(child: button);
  }
}

/// Under [child], the kit's ghost (outlined) buttons show the surface they
/// sit on instead of a fill of their own. In dark mode the kit fills them
/// with the page's black, which reads as a hole on a lifted surface such
/// as a card or a dialog. Light mode keeps the kit's white fill. Wrap only
/// ghost buttons: a filled button picks its label colour from the same
/// theme colour.
class GhostFill extends StatelessWidget {
  const GhostFill({super.key, required this.child, this.applies = true});

  final Widget child;

  /// False leaves [child] as it is, for a button that is only sometimes
  /// a ghost.
  final bool applies;

  @override
  Widget build(BuildContext context) {
    final theme = context.fluffyTheme;
    if (!applies || !theme.isDark) {
      return child;
    }

    // The kit's ghost fill in dark mode is neutral7; nothing else a ghost
    // button draws there uses it, so only the fill turns see-through.
    return FluffyTheme(
      data: theme.copyWith(
        colors: theme.colors.copyWith(neutral7: const Color(0x00000000)),
      ),
      child: child,
    );
  }
}
