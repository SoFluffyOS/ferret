import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The device actions: ask for a link, send it, and say what happened.
abstract final class SendFlows {
  static Future<void> sendLink(
    BuildContext context,
    HandoffViewModel viewModel,
    DeviceStatus device,
  ) async {
    final l10n = context.handoffL10n;
    final name = device.device.name;
    final text = await FerretTextDialog.show(
      context,
      title: l10n.sendLinkTitle(name),
      labelText: l10n.sendLinkLabel,
      hintText: l10n.sendLinkHint,
      cancelText: l10n.cancel,
      confirmText: l10n.send,
    );
    if (text == null || !context.mounted) {
      return;
    }

    final outcome = await viewModel.sendText(device.device.id, text);
    if (!context.mounted) {
      return;
    }

    if (outcome == null) {
      context.toastError(l10n.sendEmpty);
      return;
    }

    report(context, outcome, name);
  }

  static Future<void> sendCurrentPage(
    BuildContext context,
    HandoffViewModel viewModel,
    DeviceStatus device,
  ) async {
    final l10n = context.handoffL10n;
    final name = device.device.name;
    final result = await viewModel.sendCurrentPage(device.device.id);
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case PageSent(:final outcome):
        report(context, outcome, name);
      case PageMissing():
        context.toastError(l10n.currentPageNone);
      case PageDenied():
        context.toastError(l10n.currentPageDenied);
      case PageUnreadable():
        context.toastError(l10n.currentPageFailed);
    }
  }

  static void report(BuildContext context, SendOutcome outcome, String name) {
    final l10n = context.handoffL10n;
    switch (outcome) {
      case .opened:
        context.toast(l10n.sendOpened(name), type: .success);
      case .suggested:
        context.toast(l10n.sendSuggested(name));
      case .failed:
        context.toastError(l10n.sendFailed(name));
      case .unreachable:
        context.toastError(l10n.sendUnreachable(name));
    }
  }
}
