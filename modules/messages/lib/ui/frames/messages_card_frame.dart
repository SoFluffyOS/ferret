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

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, phone) in phones.indexed) ...[
          if (index > 0) Spacing.v8,
          _PhoneCard(phone: phone, onOpen: () => onOpen(phone.deviceId)),
        ],
      ],
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.phone, required this.onOpen});

  final PhoneSummary phone;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final latest = phone.latest;
    final subtitle = switch (phone.readiness) {
      .offline => l10n.statusOffline(phone.name),
      _ => l10n.unreadCount(phone.unread),
    };

    return SurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: Spacing.d20,
                color: palette.text,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      '${l10n.title} · ${phone.name}',
                      style: typography.base1.copyWith(color: palette.text),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                    Spacing.vertical(Spacing.d2),
                    Text(
                      subtitle,
                      style: typography.caption1.copyWith(
                        color: switch (phone.unread > 0) {
                          true => palette.accent,
                          false => palette.mutedText,
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Button(variant: .secondary, label: l10n.open, onPressed: onOpen),
            ],
          ),
          if (latest != null) ...[
            Spacing.v8,
            Text(
              switch (latest.snippet.isEmpty) {
                true => '${latest.title}: ${l10n.attachment}',
                false => '${latest.title}: ${latest.snippet}',
              },
              style: typography.caption1.copyWith(color: palette.mutedText),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
