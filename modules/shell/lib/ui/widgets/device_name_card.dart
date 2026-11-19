import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Naming a paired device on this one only, and pinning it to the top of
/// the list. Quiet lines until the user asks; when another device has the
/// same name, it says so and offers the rename right away.
class DeviceNameCard extends StatefulWidget {
  const DeviceNameCard({
    super.key,
    required this.ownName,
    required this.nickname,
    required this.hasNamesake,
    required this.here,
    required this.isPinned,
    required this.onRename,
    required this.onPin,
  });

  /// What the device calls itself.
  final String ownName;

  /// The name the user gave it here, if any.
  final String? nickname;

  /// Another paired device without a nickname has the same name.
  final bool hasNamesake;

  /// What to call the device Ferret runs on, such as "this Mac".
  final String here;

  final bool isPinned;

  /// Saves a new name here, or null to go back to its own name.
  final ValueChanged<String?> onRename;
  final ValueChanged<bool> onPin;

  @override
  State<DeviceNameCard> createState() => _DeviceNameCardState();
}

class _DeviceNameCardState extends State<DeviceNameCard> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _editing = false;

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _edit() {
    _name
      ..text = widget.nickname ?? widget.ownName
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: _name.text.length,
      );
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _save(String? name) {
    widget.onRename(name);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    if (_editing) {
      return Padding(
        padding: EdgeInsets.only(top: Spacing.d8),
        child: SurfaceCard(
          padding: EdgeInsets.all(Spacing.d16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.deviceRenameTitle(widget.here),
                style: typography.base1.copyWith(color: palette.text),
              ),
              Spacing.v4,
              Text(
                l10n.deviceRenameBody(widget.here, widget.ownName),
                style: typography.base2.copyWith(color: palette.mutedText),
              ),
              Spacing.v12,
              InputText(
                controller: _name,
                focusNode: _focus,
                hintText: widget.ownName,
                maxLength: 40,
                onSubmitted: _save,
              ),
              Spacing.v12,
              Wrap(
                spacing: Spacing.d8,
                runSpacing: Spacing.d8,
                children: [
                  Button(
                    mainAxisSize: .min,
                    variant: .ghost,
                    label: l10n.deviceRenameSave,
                    onPressed: () => _save(_name.text),
                  ),
                  if (widget.nickname != null)
                    Button(
                      mainAxisSize: .min,
                      variant: .ghost,
                      label: l10n.deviceRenameReset,
                      onPressed: () => _save(null),
                    ),
                  Button(
                    mainAxisSize: .min,
                    variant: .ghost,
                    label: l10n.cancel,
                    onPressed: () => setState(() => _editing = false),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (widget.hasNamesake)
          Padding(
            padding: EdgeInsets.only(top: Spacing.d8),
            child: SurfaceCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.deviceSameName(widget.ownName),
                      style: typography.base2.copyWith(color: palette.text),
                    ),
                  ),
                  Spacing.h12,
                  Button(
                    mainAxisSize: .min,
                    variant: .ghost,
                    label: l10n.deviceRename,
                    onPressed: _edit,
                  ),
                ],
              ),
            ),
          ),
        if (!widget.hasNamesake) _QuietLine(l10n.deviceRename, onTap: _edit),
        _QuietLine(
          switch (widget.isPinned) {
            true => l10n.devicesUnpin,
            false => l10n.devicesPin,
          },
          onTap: () => widget.onPin(!widget.isPinned),
        ),
      ],
    );
  }
}

class _QuietLine extends StatelessWidget {
  const _QuietLine(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PageInsets.row,
          vertical: Spacing.d12,
        ),
        child: Text(
          label,
          style: context.fluffyTheme.typography.base2.copyWith(
            color: context.palette.link,
          ),
        ),
      ),
    );
  }
}
