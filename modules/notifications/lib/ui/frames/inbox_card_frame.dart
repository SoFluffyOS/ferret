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
/// or what keeps them from arriving.
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
      (viewModel) => viewModel.phones,
    );
    final inbox = context.read<InboxViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final names = {for (final phone in phones) phone.deviceId: phone.name};
    final troubled = [
      for (final phone in phones)
        if ((!phone.isMirroring && phone.settings != null) || phone.unreachable)
          phone,
    ];

    final groups = [
      for (final phone in troubled)
        Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              phone.name,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            PhoneStatusLine(phone: phone),
          ],
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
      subtitle: _emptyLine(context, phones, byDevice, troubled),
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) Spacing.v8,
          group,
        ],
      ],
      actions: [
        if (byDevice.isNotEmpty)
          Button(
            variant: .secondary,
            label: l10n.clearAll,
            onPressed: inbox.clearAll,
          ),
      ],
    );
  }

  String? _emptyLine(
    BuildContext context,
    List<PhoneStatus> phones,
    Map<String, List<MirroredNotification>> byDevice,
    List<PhoneStatus> troubled,
  ) {
    if (byDevice.isNotEmpty) {
      return null;
    }

    final l10n = context.notificationsL10n;
    if (phones.isEmpty) {
      return l10n.noPhone;
    }
    if (troubled.isEmpty) {
      return l10n.homeEmpty;
    }
    return null;
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
