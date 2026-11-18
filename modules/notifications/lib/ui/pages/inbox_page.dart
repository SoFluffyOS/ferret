import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/frames/frames.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Every notification this computer keeps from its phones, opened from
/// their line in Activity.
class InboxPage extends StatelessWidget {
  const InboxPage({super.key, required this.inbox, required this.phones});

  final InboxViewModel inbox;

  /// Makes the page's own view of the paired phones, disposed with it.
  final PhonesViewModel Function() phones;

  @override
  Widget build(BuildContext context) {
    final l10n = context.notificationsL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: inbox),
            ChangeNotifierProvider(create: (_) => phones()),
          ],
          child: const InboxCardFrame(
            shownPerPhone: InboxViewModel.keptPerDevice,
          ),
        ),
      ],
    );
  }
}
