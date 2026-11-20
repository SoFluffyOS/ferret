import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says when a device joined through another of the user's devices, with a
/// way to undo it here. Also sends a system notification, because nobody
/// was looking at this device when it happened. Several that join at once,
/// as when a family of devices meets a new one, make one card and one
/// notification, not one each.
class JoinedNoticesFrame extends StatefulWidget {
  const JoinedNoticesFrame({super.key});

  @override
  State<JoinedNoticesFrame> createState() => _JoinedNoticesFrameState();
}

class _JoinedNoticesFrameState extends State<JoinedNoticesFrame> {
  /// A device that just paired here gets its new family without a word:
  /// the user is in the middle of exactly that.
  static const _justPaired = Duration(minutes: 2);

  /// The one system notification about who joined, updated as more do.
  static const _noticeId = 'shell.joined';

  final List<DeviceJoined> _joined = [];
  bool _reviewing = false;
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
    _notify();
  }

  void _notify() {
    final notifier = ShellScope.read(context).featureContext.notifier;
    if (_joined.isEmpty) {
      unawaited(notifier.cancel(_noticeId));
      return;
    }

    final l10n = context.shellL10n;
    final notice = switch (_joined) {
      [final joined] => LocalNotice(
        id: _noticeId,
        channel: .incoming,
        title: l10n.joinedNotice(joined.device.name),
        body: l10n.joinedNoticeBody(joined.introducer.name),
      ),
      _ => LocalNotice(
        id: _noticeId,
        channel: .incoming,
        title: l10n.joinedManyNotice(_joined.length),
        body: JoinedSummary(_joined).names,
      ),
    };
    unawaited(notifier.show(notice));
  }

  void _keep(DeviceJoined joined) {
    setState(() => _joined.remove(joined));
    _notify();
  }

  void _keepAll() {
    setState(() {
      _joined.clear();
      _reviewing = false;
    });
    _notify();
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

    if (_joined.length > 1 && !_reviewing) {
      return Padding(
        padding: EdgeInsets.only(top: Spacing.d8),
        child: SurfaceCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.joinedManyBanner(JoinedSummary(_joined).names),
                      style: typography.base2.copyWith(color: palette.text),
                    ),
                    if (JoinedSummary(_joined).introducer
                        case final introducer?)
                      Text(
                        l10n.joinedManyAddedBy(introducer),
                        style: typography.caption1.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                  ],
                ),
              ),
              Spacing.h12,
              GhostButton(
                mainAxisSize: .min,
                label: l10n.joinedReview,
                onPressed: () => setState(() => _reviewing = true),
              ),
              Spacing.h8,
              GhostButton(
                mainAxisSize: .min,
                label: l10n.joinedKeepAll,
                onPressed: _keepAll,
              ),
            ],
          ),
        ),
      );
    }

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
                  GhostButton(
                    mainAxisSize: .min,
                    label: l10n.joinedUndo,
                    onPressed: () => _undo(joined),
                  ),
                  Spacing.h8,
                  GhostButton(
                    mainAxisSize: .min,
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
