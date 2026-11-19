import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class RcsNote extends StatelessWidget {
  const RcsNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
    child: Text(
      context.messagesL10n.rcsNote,
      style: context.fluffyTheme.typography.caption1.copyWith(
        color: context.palette.mutedText,
      ),
    ),
  );
}
