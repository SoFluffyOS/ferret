import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/ui/frames/frames.dart';
import 'package:media/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The full controls for what plays on another device, opened from its
/// Activity line: progress, seek, previous and "Continue here".
class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key, required this.viewModel});

  final MediaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.mediaL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const NowPlayingFrame(),
        ),
      ],
    );
  }
}
