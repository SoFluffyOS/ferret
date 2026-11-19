import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A field over the bottom of the picture for text that needs composing:
/// accents, emoji, another language, dictation. Enter sends it to the
/// device as text, Escape closes the field.
class MirrorTextFieldFrame extends StatefulWidget {
  const MirrorTextFieldFrame({super.key, this.onClosed});

  /// The field went away, so the picture can have the keyboard back.
  final VoidCallback? onClosed;

  @override
  State<MirrorTextFieldFrame> createState() => _MirrorTextFieldFrameState();
}

class _MirrorTextFieldFrameState extends State<MirrorTextFieldFrame> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send(ViewerViewModel viewModel) {
    viewModel.sendComposed(_text.text);
    _text.clear();
    _focus.requestFocus();
  }

  void _close(ViewerViewModel viewModel) {
    viewModel.closeTextField();
    widget.onClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _close(viewModel),
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d360),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: Corners.shape(Corners.card),
            shadows: [
              BoxShadow(
                color: palette.text.withValues(alpha: 0.18),
                blurRadius: Spacing.d16,
                offset: Offset(0, Spacing.d4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(Spacing.d6),
            child: Row(
              children: [
                Expanded(
                  child: InputText(
                    controller: _text,
                    focusNode: _focus,
                    hintText: l10n.textFieldHint,
                    textInputAction: .send,
                    onSubmitted: (_) => _send(viewModel),
                  ),
                ),
                Spacing.h6,
                Button(
                  variant: .primary,
                  mainAxisSize: .min,
                  label: l10n.send,
                  onPressed: () => _send(viewModel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
