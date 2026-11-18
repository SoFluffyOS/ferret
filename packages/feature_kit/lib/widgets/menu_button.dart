import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/menu_entry.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// An icon that opens a short menu right under itself. The menu closes on
/// a pick, a tap anywhere else, or Escape. Used where a dialog would be too
/// much, such as the "more" menu in the popover.
class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.entries,
  });

  final IconData icon;
  final String tooltip;
  final List<MenuEntry> entries;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  final OverlayPortalController _menu = OverlayPortalController();
  final LayerLink _anchor = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _anchor,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: (_) => _MenuOverlay(
          anchor: _anchor,
          entries: widget.entries,
          onClose: _menu.hide,
        ),
        child: Tappable(
          tooltip: widget.tooltip,
          onTap: _menu.toggle,
          child: Padding(
            padding: EdgeInsets.all(Spacing.d6),
            child: Icon(
              widget.icon,
              size: Spacing.d20,
              color: context.palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.anchor,
    required this.entries,
    required this.onClose,
  });

  final LayerLink anchor;
  final List<MenuEntry> entries;
  final VoidCallback onClose;

  static const _shadow = Color(0x33000000);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(behavior: .opaque, onTap: onClose),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: CompositedTransformFollower(
                link: anchor,
                showWhenUnlinked: false,
                targetAnchor: .bottomRight,
                followerAnchor: .topRight,
                offset: Offset(0, Spacing.d4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(Spacing.d12),
                    boxShadow: [
                      BoxShadow(
                        color: _shadow,
                        blurRadius: Spacing.d24,
                        offset: Offset(0, Spacing.d8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.d6),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          for (final entry in entries) ...[
                            if (entry.startsGroup) const _Divider(),
                            _MenuRow(entry: entry, onClose: onClose),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.entry, required this.onClose});

  final MenuEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Tappable(
      onTap: () {
        onClose();
        entry.onSelected();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d16,
          vertical: Spacing.d10,
        ),
        child: Row(
          children: [
            if (entry.icon case final icon?) ...[
              Icon(icon, size: Spacing.d16, color: palette.mutedText),
              Spacing.h12,
            ],
            Text(
              entry.label,
              style: context.fluffyTheme.typography.base2.copyWith(
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: ColoredBox(
        color: context.palette.mutedText.withValues(alpha: 0.2),
        child: SizedBox(height: Spacing.d1),
      ),
    );
  }
}
