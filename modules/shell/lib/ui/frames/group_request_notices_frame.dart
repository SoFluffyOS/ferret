import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// Sends a system notification when another of the person's devices wants
/// to add or remove one here, because nobody may be looking at this device.
/// The question itself waits under Needs you. Several at once make one
/// notification, not one each.
class GroupRequestNoticesFrame extends StatefulWidget {
  const GroupRequestNoticesFrame({super.key});

  @override
  State<GroupRequestNoticesFrame> createState() =>
      _GroupRequestNoticesFrameState();
}

class _GroupRequestNoticesFrameState extends State<GroupRequestNoticesFrame> {
  /// The one system notification about requests, updated as more come.
  static const _noticeId = 'shell.groupRequests';

  StreamSubscription<List<GroupRequest>>? _requests;

  @override
  void initState() {
    super.initState();
    final engine = ShellScope.read(context).featureContext.engine;
    _requests = engine.groupRequestChanges.listen(_notify);
  }

  @override
  void dispose() {
    unawaited(_requests?.cancel());
    super.dispose();
  }

  void _notify(List<GroupRequest> requests) {
    final featureContext = ShellScope.read(context).featureContext;
    final notifier = featureContext.notifier;
    final l10n = context.shellL10n;
    final here = l10n.here(featureContext.engine.device);
    final notice = switch (requests) {
      [] => null,
      [final request] => LocalNotice(
        id: _noticeId,
        channel: .incoming,
        title: GroupRequestItems.question(l10n, here, request),
        body: l10n.groupRequestNoticeBody,
      ),
      _ => LocalNotice(
        id: _noticeId,
        channel: .incoming,
        title: l10n.groupRequestsNotice(requests.length),
        body: ListText.join([
          for (final request in requests) request.device.name,
        ]),
      ),
    };
    switch (notice) {
      case final notice?:
        unawaited(notifier.show(notice));
      case null:
        unawaited(notifier.cancel(_noticeId));
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
