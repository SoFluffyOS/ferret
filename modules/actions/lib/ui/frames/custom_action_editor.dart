import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The form for one of the owner's own actions, in place in the list: its
/// name, what it runs, Save, and Remove for one that exists. Save waits
/// for both fields.
class CustomActionEditor extends StatefulWidget {
  const CustomActionEditor({
    super.key,
    required this.action,
    required this.onSave,
    required this.onCancel,
    this.onRemove,
  });

  /// The action being changed, or null for a new one.
  final CustomAction? action;
  final void Function(String name, String commandLine) onSave;
  final VoidCallback onCancel;
  final VoidCallback? onRemove;

  @override
  State<CustomActionEditor> createState() => _CustomActionEditorState();
}

class _CustomActionEditorState extends State<CustomActionEditor> {
  late final TextEditingController _name = .new(text: widget.action?.name);
  late final TextEditingController _command = .new(
    text: widget.action?.commandLine,
  );

  @override
  void initState() {
    super.initState();
    _name.addListener(_onEdited);
    _command.addListener(_onEdited);
  }

  @override
  void dispose() {
    _name.dispose();
    _command.dispose();
    super.dispose();
  }

  void _onEdited() => setState(() {});

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _command.text.trim().isNotEmpty;

  bool get _changedCommand {
    final before = widget.action?.commandLine;
    return before != null && before != _command.text.trim();
  }

  void _save() {
    if (!_canSave) {
      return;
    }

    widget.onSave(_name.text, _command.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;
    final seconds = context.read<ActionsViewModel>().commandSeconds;
    final note = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );

    return GroupedCell(
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          InputText(
            controller: _name,
            label: l10n.editName,
            hintText: l10n.editNameHint,
            textInputAction: .next,
          ),
          Spacing.v12,
          InputText(
            controller: _command,
            label: l10n.editCommand,
            hintText: _commandHint,
            onSubmitted: (_) => _save(),
          ),
          Spacing.v8,
          Text(l10n.editCommandHelp(seconds), style: note),
          if (_changedCommand) ...[
            Spacing.v4,
            Text(l10n.editCommandChanged, style: note),
          ],
          Spacing.v12,
          Wrap(
            spacing: Spacing.d8,
            runSpacing: Spacing.d8,
            children: [
              Button(
                mainAxisSize: .min,
                variant: .primary,
                enable: _canSave,
                label: l10n.save,
                onPressed: _save,
              ),
              Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.cancel,
                onPressed: widget.onCancel,
              ),
              if (widget.onRemove case final onRemove?)
                Button(
                  mainAxisSize: .min,
                  variant: .ghost,
                  label: l10n.remove,
                  onPressed: onRemove,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// An example in the form this computer runs, never translated: it is
  /// something to type.
  String get _commandHint => switch (ComputerKind.here) {
    .mac => 'shortcuts run "Good night"',
    .windows => r'C:\Scripts\good-night.ps1',
    .linux => '~/bin/good-night.sh',
  };
}
