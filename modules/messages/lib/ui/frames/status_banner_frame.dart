import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Why the phone's texts are only saved ones, or can't load, with a fix.
/// Nothing when everything works.
class StatusBannerFrame extends StatelessWidget {
  const StatusBannerFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final readiness = context.select<InboxViewModel, PhoneReadiness>(
      (viewModel) => viewModel.phone.readiness,
    );
    final syncing = context.select<InboxViewModel, bool>(
      (viewModel) => viewModel.phone.syncing,
    );
    final loadFailed = context.select<InboxViewModel, bool>(
      (viewModel) => viewModel.loadFailed,
    );
    final viewModel = context.read<InboxViewModel>();
    final name = viewModel.phoneName;
    final l10n = context.messagesL10n;

    final (String? text, StatusTone tone, bool canRetry) = switch (readiness) {
      // The device's page already says it is offline, and since when.
      .offline => (null, StatusTone.info, false),
      .checking => (l10n.statusChecking(name), StatusTone.info, false),
      .off => (l10n.statusOff(name), StatusTone.warning, true),
      .noAccess => (l10n.statusNoAccess(name), StatusTone.warning, true),
      .unreachable => (l10n.statusUnreachable(name), StatusTone.warning, true),
      .ready when loadFailed => (
        l10n.loadFailed(name),
        StatusTone.warning,
        true,
      ),
      .ready when syncing => (l10n.syncing, StatusTone.info, false),
      .ready => (null, StatusTone.info, false),
    };
    if (text == null) {
      return const SizedBox.shrink();
    }

    return StatusBanner(
      text: text,
      tone: tone,
      actionLabel: switch (canRetry) {
        true => l10n.retry,
        false => null,
      },
      onAction: viewModel.retry,
    );
  }
}
