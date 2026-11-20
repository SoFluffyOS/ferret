import 'package:feature_kit/widgets/focus_rings.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The design system's outlined (ghost) button that wears one ring at a
/// time: focused from the keyboard, its grey outline gives way to the
/// accent focus ring. Takes the same arguments as `Button`.
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
    return ButtonFocusRing(
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
  }
}
