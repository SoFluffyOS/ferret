import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// While in control: the touchpad takes all the height left over by the
/// mouse buttons, the keyboard row and the keys, so nothing on the page
/// scrolls. **Keyboard** shows the on-screen keyboard and **Hide keyboard**
/// (or a touch on the pad) puts it away.
class TouchpadControlsFrame extends StatefulWidget {
  const TouchpadControlsFrame({super.key, required this.hostKind});

  final HostKind hostKind;

  @override
  State<TouchpadControlsFrame> createState() => _TouchpadControlsFrameState();
}

class _TouchpadControlsFrameState extends State<TouchpadControlsFrame> {
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _keyboardFocus.addListener(_onKeyboardFocus);
  }

  @override
  void dispose() {
    _keyboardFocus
      ..removeListener(_onKeyboardFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final armed = context.select<TouchpadViewModel, Set<KeyModifier>>(
      (viewModel) => viewModel.armed,
    );
    final viewModel = context.read<TouchpadViewModel>();
    final l10n = context.remoteInputL10n;
    final keyboardShown = _keyboardFocus.hasFocus;
    final (keyboardLabel, keyboardIcon) = switch (keyboardShown) {
      true => (l10n.hideKeyboard, LucideIcons.keyboardOff),
      false => (l10n.showKeyboard, LucideIcons.keyboard),
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: TouchpadSurface(sink: viewModel, hint: l10n.touchpadHint),
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: HoldButton(
                label: l10n.leftButton,
                onPress: () => viewModel.press(.left),
                onRelease: () => viewModel.release(.left),
              ),
            ),
            Spacing.h8,
            Expanded(
              child: HoldButton(
                label: l10n.rightButton,
                onPress: () => viewModel.press(.right),
                onRelease: () => viewModel.release(.right),
              ),
            ),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: KeyboardField(
                hint: l10n.keyboardHint,
                focusNode: _keyboardFocus,
                onChanged: viewModel.typed,
                onEnter: () => viewModel.tapKey(.enter),
              ),
            ),
            Spacing.h8,
            Button(
              mainAxisSize: .min,
              variant: .ghost,
              label: keyboardLabel,
              icon: Icon(keyboardIcon, size: Spacing.d16),
              onPressed: _toggleKeyboard,
            ),
          ],
        ),
        Spacing.v8,
        KeyStrip(
          keys: [
            KeyChip(
              label: l10n.keyEscape,
              tooltip: l10n.keyEscape,
              onTap: () => viewModel.tapKey(.escape),
            ),
            KeyChip(
              label: l10n.keyTab,
              tooltip: l10n.keyTab,
              onTap: () => viewModel.tapKey(.tab),
            ),
            KeyChip(
              icon: LucideIcons.arrowLeft,
              tooltip: l10n.keyLeft,
              onTap: () => viewModel.tapKey(.arrowLeft),
            ),
            KeyChip(
              icon: LucideIcons.arrowUp,
              tooltip: l10n.keyUp,
              onTap: () => viewModel.tapKey(.arrowUp),
            ),
            KeyChip(
              icon: LucideIcons.arrowDown,
              tooltip: l10n.keyDown,
              onTap: () => viewModel.tapKey(.arrowDown),
            ),
            KeyChip(
              icon: LucideIcons.arrowRight,
              tooltip: l10n.keyRight,
              onTap: () => viewModel.tapKey(.arrowRight),
            ),
            KeyChip(
              icon: LucideIcons.delete,
              tooltip: l10n.keyBackspace,
              onTap: () => viewModel.tapKey(.backspace),
            ),
            KeyChip(
              icon: LucideIcons.cornerDownLeft,
              tooltip: l10n.keyEnter,
              onTap: () => viewModel.tapKey(.enter),
            ),
          ],
        ),
        Spacing.v8,
        KeyStrip(
          keys: [
            for (final modifier in KeyModifier.values)
              KeyChip(
                label: l10n.modifierLabel(modifier, widget.hostKind),
                tooltip: l10n.modifierLabel(modifier, widget.hostKind),
                selected: armed.contains(modifier),
                onTap: () => viewModel.toggleModifier(modifier),
              ),
            KeyChip(
              icon: LucideIcons.skipBack,
              tooltip: l10n.mediaPrevious,
              onTap: () => viewModel.tapKey(.mediaPrevious),
            ),
            KeyChip(
              icon: LucideIcons.play,
              tooltip: l10n.mediaPlayPause,
              onTap: () => viewModel.tapKey(.mediaPlayPause),
            ),
            KeyChip(
              icon: LucideIcons.skipForward,
              tooltip: l10n.mediaNext,
              onTap: () => viewModel.tapKey(.mediaNext),
            ),
            KeyChip(
              icon: LucideIcons.volume1,
              tooltip: l10n.volumeDown,
              onTap: () => viewModel.tapKey(.volumeDown),
            ),
            KeyChip(
              icon: LucideIcons.volumeX,
              tooltip: l10n.volumeMute,
              onTap: () => viewModel.tapKey(.volumeMute),
            ),
            KeyChip(
              icon: LucideIcons.volume2,
              tooltip: l10n.volumeUp,
              onTap: () => viewModel.tapKey(.volumeUp),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleKeyboard() {
    if (_keyboardFocus.hasFocus) {
      _keyboardFocus.unfocus();
      return;
    }

    _keyboardFocus.requestFocus();
  }

  void _onKeyboardFocus() => setState(() {});
}
