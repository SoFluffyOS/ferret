import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/ui/frames/frames.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// Recent clips, opened from the ••• menu or the File menu.
class RecentClipsPage extends StatelessWidget {
  const RecentClipsPage({super.key, required this.showsPreviewsFrom});

  final bool Function(String deviceId) showsPreviewsFrom;

  @override
  Widget build(BuildContext context) => FerretPage(
    title: context.clipboardL10n.recentClips,
    children: [RecentClipsFrame(showsPreviewsFrom: showsPreviewsFrom)],
  );
}
