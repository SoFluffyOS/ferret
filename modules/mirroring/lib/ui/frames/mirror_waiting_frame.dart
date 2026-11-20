import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// While the phone asks its owner: what to tap there, in words that hold
/// on any Android, how long the question stays, and what to do when the
/// phone shows nothing.
class MirrorWaitingFrame extends StatefulWidget {
  const MirrorWaitingFrame({
    super.key,
    required this.deviceName,
    required this.until,
    required this.onCancel,
    this.asksEveryTime = false,
    this.camera = false,
    this.clock,
  });

  /// How long the phone may take before "nothing on the phone?" shows.
  static const quietAfter = Duration(seconds: 8);

  final String deviceName;

  /// When the question on the phone runs out.
  final DateTime? until;
  final VoidCallback onCancel;

  /// Says once why the phone asks every single time.
  final bool asksEveryTime;

  /// The phone's camera is asked for: its owner answers in Ferret, not
  /// Android's screen capture prompt.
  final bool camera;
  final DateTime Function()? clock;

  @override
  State<MirrorWaitingFrame> createState() => _MirrorWaitingFrameState();
}

class _MirrorWaitingFrameState extends State<MirrorWaitingFrame> {
  late final DateTime _since = _now();

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  bool get _isQuiet =>
      _now().difference(_since) >= MirrorWaitingFrame.quietAfter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final caption = context.fluffyTheme.typography.caption1.copyWith(
      color: palette.mutedText,
    );
    final until = widget.until;
    final deviceName = widget.deviceName;

    return MirrorMessage(
      icon: LucideIcons.smartphone,
      tone: .accent,
      title: l10n.waitingTitle(deviceName),
      body: switch (widget.camera) {
        true => l10n.cameraWaitingBody(deviceName),
        false => l10n.waitingBody(deviceName),
      },
      actions: [MessageAction(label: l10n.cancel, onPressed: widget.onCancel)],
      children: [
        if (until != null)
          Countdown(
            until: until,
            clock: widget.clock,
            builder: (context, left) => Column(
              mainAxisSize: .min,
              children: [
                if (_isQuiet) ...[
                  Spacing.v8,
                  Text(
                    switch (widget.camera) {
                      true => l10n.cameraWaitingNothing(deviceName),
                      false => l10n.waitingNothing(deviceName),
                    },
                    textAlign: .center,
                    style: caption,
                  ),
                ],
                Spacing.v12,
                Row(
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      LucideIcons.timer,
                      size: Spacing.d14,
                      color: palette.mutedText,
                    ),
                    Spacing.h4,
                    Text(
                      l10n.timeLeft(Countdown.clockText(left)),
                      style: caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (widget.asksEveryTime) ...[
          Spacing.v8,
          Text(l10n.waitingWhy, textAlign: .center, style: caption),
        ],
      ],
    );
  }
}
