import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on a computer: the last few notifications from each phone,
/// or what keeps them from arriving, in words that match the device tile.
class InboxCardFrame extends StatelessWidget {
  const InboxCardFrame({super.key});

  static const _shownPerPhone = 3;

  @override
  Widget build(BuildContext context) {
    final byDevice = context
        .select<InboxViewModel, Map<String, List<MirroredNotification>>>(
          (viewModel) => viewModel.byDevice,
        );
    final phones = context.select<PhonesViewModel, List<PhoneStatus>>(
      (viewModel) => viewModel.pairedPhones,
    );
    final inbox = context.read<InboxViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final names = {
      for (final phone in phones)
        if (phone.online) phone.deviceId: phone.name,
    };
    final troubled = [
      for (final phone in phones)
        if (_problem(context, phone) case final problem?) (phone, problem),
    ];
    final turnedOff = [
      for (final (phone, _) in troubled)
        if (phone.state == .off) phone,
    ];
    final soleProblem = switch (troubled) {
      [(_, final problem)] when byDevice.isEmpty => problem,
      _ => null,
    };

    final groups = [
      if (soleProblem == null)
        for (final (_, problem) in troubled)
          Text(
            problem,
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
      for (final MapEntry(key: deviceId, value: items) in byDevice.entries)
        Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              _deviceLabel(context, deviceId, names),
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            for (final notification in items.take(_shownPerPhone))
              NotificationRow(
                key: ValueKey('${notification.deviceId}/${notification.key}'),
                notification: notification,
                dismissLabel: l10n.dismiss,
                onDismiss: () => inbox.dismiss(notification),
              ),
          ],
        ),
    ];

    return FeatureCard(
      icon: LucideIcons.bell,
      title: l10n.title,
      subtitle: soleProblem ?? _emptyLine(context, byDevice, troubled.length),
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) Spacing.v8,
          group,
        ],
      ],
      actions: [
        if (turnedOff case [final phone, ...])
          Button(
            variant: .ghost,
            label: l10n.how,
            onPressed: () => unawaited(_explain(context, phone.name)),
          ),
        if (byDevice.isNotEmpty)
          Button(
            variant: .ghost,
            label: l10n.clearAll,
            onPressed: inbox.clearAll,
          ),
      ],
    );
  }

  String? _problem(BuildContext context, PhoneStatus phone) {
    final l10n = context.notificationsL10n;

    return switch (phone.state) {
      .offline => l10n.homeOffline(phone.name),
      .off => l10n.homeTurnOn(phone.name),
      .unreachable => l10n.homeUnreachable(phone.name),
      .accessOff => l10n.homeAccessOff(phone.name),
      .checking || .mirroring => null,
    };
  }

  String? _emptyLine(
    BuildContext context,
    Map<String, List<MirroredNotification>> byDevice,
    int troubledCount,
  ) {
    if (byDevice.isNotEmpty || troubledCount > 0) {
      return null;
    }

    return context.notificationsL10n.homeEmpty;
  }

  Future<void> _explain(BuildContext context, String phoneName) async {
    final l10n = context.notificationsL10n;

    await ContentDialog.show(
      context,
      title: l10n.howTitle(phoneName),
      content: l10n.howBody(phoneName),
      neutralText: l10n.ok,
    );
  }

  String _deviceLabel(
    BuildContext context,
    String deviceId,
    Map<String, String> connectedNames,
  ) {
    if (connectedNames[deviceId] case final name?) {
      return name;
    }

    final name = context.read<InboxViewModel>().deviceName(deviceId);
    return '$name · ${context.notificationsL10n.offline}';
  }
}
