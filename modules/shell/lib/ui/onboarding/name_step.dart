import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/onboarding/onboarding_layout.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Lets people give this device a name they'll recognise on the others.
class NameStep extends StatefulWidget {
  const NameStep({
    super.key,
    required this.total,
    required this.initialName,
    required this.onNext,
  });

  final int total;
  final String initialName;
  final ValueChanged<String> onNext;

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _name = .new(text: widget.initialName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return OnboardingLayout(
      step: 2,
      total: widget.total,
      icon: LucideIcons.pencil,
      title: l10n.onboardNameTitle,
      body: l10n.onboardNameBody,
      actions: [
        Button(
          variant: .primary,
          label: l10n.onboardContinue,
          onPressed: _next,
        ),
      ],
      child: InputText(
        controller: _name,
        label: l10n.onboardNameLabel,
        maxLength: 40,
        textInputAction: .done,
        onSubmitted: (_) => _next(),
      ),
    );
  }

  void _next() {
    final name = _name.text.trim();
    widget.onNext(switch (name.isEmpty) {
      true => widget.initialName,
      false => name,
    });
  }
}
