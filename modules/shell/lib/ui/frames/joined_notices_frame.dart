import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says when a device joined through another of the user's devices, with a
/// way to undo it here. Also sends a system notification, because nobody
/// was looking at this device when it happened.
class JoinedNoticesFrame extends StatefulWidget {
  const JoinedNoticesFrame({super.key});

  @override
  State<JoinedNoticesFrame> createState() => _JoinedNoticesFrameState();
}

class _JoinedNoticesFrameState extends State<JoinedNoticesFrame> {
  /// A device that just paired here gets its new family without a word:
  /// the user is in the middle of exactly that.
  static const _justPaired = Duration(minutes: 2);

  final List<DeviceJoined> _joined = [];
  StreamSubscription<DeviceJoined>? _joins;

  @override
  void initState() {
    super.initState();
    final engine = ShellScope.read(context).featureContext.engine;
    _joins = engine.joins.listen(_onJoined);
  }

  @override
  void dispose() {
    unawaited(_joins?.cancel());
    super.dispose();
  }

  void _onJoined(DeviceJoined joined) {
    final sincePairing = DateTime.now().difference(joined.introducer.pairedAt);
    if (sincePairing < _justPaired) {
      return;
    }

    setState(() => _joined.add(joined));
    final l10n = context.shellL10n;
    unawaited(
      ShellScope.read(context).featureContext.notifier.show(
        LocalNotice(
          id: _noticeId(joined),
          channel: .incoming,
          title: l10n.joinedNotice(joined.device.name),
          body: l10n.joinedNoticeBody(joined.introducer.name),
        ),
      ),
    );
  }

  String _noticeId(DeviceJoined joined) => 'shell.joined.${joined.device.id}';

  void _keep(DeviceJoined joined) {
    setState(() => _joined.remove(joined));
    unawaited(
      ShellScope.read(context).featureContext.notifier
          .cancel(_noticeId(joined)),
    );
  }

  /// Forgets the device on this one only. The others keep it: whoever
  /// paired it meant to.
  void _undo(DeviceJoined joined) {
    _keep(joined);
    unawaited(
      ShellScope.read(context).featureContext.engine.unpair(joined.device.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final joined in _joined)
          Padding(
            padding: EdgeInsets.only(top: Spacing.d8),
            child: SurfaceCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.joinedBanner(
                        joined.device.name,
                        joined.introducer.name,
                      ),
                      style: typography.base2.copyWith(color: palette.text),
                    ),
                  ),
                  Spacing.h12,
                  Button(
                    variant: .ghost,
                    label: l10n.joinedUndo,
                    onPressed: () => _undo(joined),
                  ),
                  Spacing.h8,
                  Button(
                    variant: .ghost,
                    label: l10n.joinedKeep,
                    onPressed: () => _keep(joined),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
