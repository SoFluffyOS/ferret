import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';

/// Another of the person's devices wants to add or remove one here, as
/// lines under Needs you. Nothing changes until they answer.
abstract final class GroupRequestItems {
  static List<ActivityItem> of(BuildContext context, FerretEngine engine) =>
      build(
        context.shellL10n,
        context.shellL10n.here(engine.device),
        engine.groupRequests,
        onAnswer: (request, {required yes}) =>
            unawaited(engine.answerGroupRequest(request, yes: yes)),
      );

  /// A line for each of [requests], whose buttons call [onAnswer]. [here]
  /// is what this device is called (see `LocalNames.here`).
  static List<ActivityItem> build(
    ShellLocalizations l10n,
    String here,
    List<GroupRequest> requests, {
    required void Function(GroupRequest request, {required bool yes}) onAnswer,
  }) => [
    for (final request in requests)
      _item(
        l10n,
        here,
        request,
        ({required yes}) => onAnswer(request, yes: yes),
      ),
  ];

  /// The sentence a line or a system notification asks.
  static String question(
    ShellLocalizations l10n,
    String here,
    GroupRequest request,
  ) => switch (request) {
    JoinRequest() => l10n.groupJoinAsk(
      request.introducer.name,
      request.device.name,
    ),
    RemovalRequest() => l10n.groupRemoveAsk(
      request.introducer.name,
      request.device.name,
      here,
    ),
  };

  static ActivityItem _item(
    ShellLocalizations l10n,
    String here,
    GroupRequest request,
    void Function({required bool yes}) answer,
  ) {
    final device = request.device.name;

    return switch (request) {
      JoinRequest() => ActivityItem(
        id: 'group.join.${request.device.id}',
        icon: LucideIcons.monitorSmartphone,
        title: question(l10n, here, request),
        detail: l10n.groupJoinAskDetail(request.introducer.name, here),
        at: request.askedAt,
        needsYou: true,
        deviceId: request.introducer.id,
        actions: [
          ActivityAction(
            label: l10n.groupJoinAdd,
            tooltip: l10n.groupJoinAddTooltip(device, here),
            primary: true,
            onPressed: () => answer(yes: true),
          ),
          ActivityAction(
            label: l10n.groupJoinNotNow,
            tooltip: l10n.groupJoinNotNowTooltip(device, here),
            onPressed: () => answer(yes: false),
          ),
        ],
      ),
      RemovalRequest() => ActivityItem(
        id: 'group.remove.${request.device.id}',
        icon: LucideIcons.monitorX,
        title: question(l10n, here, request),
        detail: l10n.groupRemoveAskDetail,
        at: request.askedAt,
        needsYou: true,
        deviceId: request.introducer.id,
        actions: [
          ActivityAction(
            label: l10n.groupRemove,
            tooltip: l10n.groupRemoveTooltip(device, here),
            primary: true,
            onPressed: () => answer(yes: true),
          ),
          ActivityAction(
            label: l10n.groupKeep,
            tooltip: l10n.groupKeepTooltip(device, here),
            onPressed: () => answer(yes: false),
          ),
        ],
      ),
    };
  }
}
