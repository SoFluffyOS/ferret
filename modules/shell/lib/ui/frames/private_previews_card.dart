import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// The switch for whether private things from one paired device show on
/// this computer's screen.
class PrivatePreviewsCard extends StatefulWidget {
  const PrivatePreviewsCard({
    super.key,
    required this.previews,
    required this.deviceId,
    required this.deviceName,
  });

  final PrivatePreviews previews;
  final String deviceId;
  final String deviceName;

  @override
  State<PrivatePreviewsCard> createState() => _PrivatePreviewsCardState();
}

class _PrivatePreviewsCardState extends State<PrivatePreviewsCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final previews = widget.previews;
    final hasChoice = previews.hasChoiceFor(widget.deviceId);
    final body = [
      l10n.previewsBody(widget.deviceName),
      if (!hasChoice && !previews.shownByDefault)
        l10n.previewsSharedDefault(ThisComputer.here),
    ].join('\n');

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.previewsTitle(ThisComputer.here),
          body: body,
          value: previews.showsFrom(widget.deviceId),
          onChanged: _set,
        ),
      ],
    );
  }

  Future<void> _set(bool shows) async {
    await widget.previews.setShows(widget.deviceId, shows: shows);
    if (mounted) {
      setState(() {});
    }
  }
}
