import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The computer's home card: unread texts per phone and the latest
/// conversation, opening the Messages page.
class MessagesCardFrame extends StatelessWidget {
  const MessagesCardFrame({super.key, required this.onOpen});

  final void Function(String deviceId) onOpen;

  @override
  Widget build(BuildContext context) {
    final phones = context.select<CardViewModel, List<PhoneSummary>>(
      (viewModel) => viewModel.phones,
    );
    if (phones.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.messagesL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, phone) in phones.indexed) ...[
          if (index > 0) Spacing.v8,
          FeatureCard(
            icon: LucideIcons.messageSquare,
            title: l10n.cardTitle(phone.name),
            subtitle: switch (phone.readiness) {
              .offline => l10n.statusOffline(phone.name),
              _ => l10n.unreadCount(phone.unread),
            },
            subtitleTone: switch ((phone.readiness, phone.unread)) {
              (.offline, _) => FeatureTone.muted,
              (_, > 0) => FeatureTone.accent,
              _ => FeatureTone.muted,
            },
            onTap: () => onOpen(phone.deviceId),
            children: [
              if (phone.latest case final latest?)
                Text(
                  switch (latest.snippet.isEmpty) {
                    true => l10n.attachmentFrom(latest.title),
                    false => l10n.latestFrom(latest.title, latest.snippet),
                  },
                  style: typography.body2.copyWith(color: palette.text),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
            ],
            actions: [
              Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.open,
                onPressed: () => onOpen(phone.deviceId),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
