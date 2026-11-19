import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The small pin next to a device the person pinned to the top, so the
/// list says why it sits there.
class PinMarker extends StatelessWidget {
  const PinMarker({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.shellL10n.devicePinned,
    child: ExcludeSemantics(
      child: Icon(
        LucideIcons.pin,
        size: Spacing.d12,
        color: context.palette.mutedText,
      ),
    ),
  );
}
