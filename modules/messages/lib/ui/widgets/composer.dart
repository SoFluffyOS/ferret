import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The reply field and Send button, or why replying isn't possible.
class Composer extends StatefulWidget {
  const Composer({super.key, required this.onSend, this.blockedReason});

  /// Returns true when the text went out, so the field clears.
  final Future<bool> Function(String text) onSend;

  /// Shown instead of the field when replies can't be sent.
  final String? blockedReason;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final TextEditingController _controller = .new();
  final FocusNode _focus = .new();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;

    if (widget.blockedReason case final reason?) {
      return Padding(
        padding: EdgeInsets.all(Spacing.d12),
        child: Text(
          reason,
          textAlign: .center,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(Spacing.d8),
      child: Row(
        crossAxisAlignment: .end,
        children: [
          Expanded(
            child: InputText(
              controller: _controller,
              focusNode: _focus,
              hintText: l10n.composerHint,
              maxLines: 5,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          Spacing.h8,
          Button(
            mainAxisSize: .min,
            variant: .primary,
            label: l10n.send,
            icon: Icon(LucideIcons.sendHorizontal, size: Spacing.d16),
            enable: _hasText,
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }

    final sent = await widget.onSend(text);
    if (!sent || !mounted) {
      return;
    }

    _controller.clear();
    _focus.requestFocus();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }
}
