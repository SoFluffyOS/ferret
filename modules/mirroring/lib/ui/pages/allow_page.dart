import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Asks whether a device may show its screen here. It comes up by itself
/// when a device asks, and goes away with the answer or when the question
/// runs out.
class AllowPage extends StatelessWidget {
  const AllowPage({super.key, required this.request});

  final IncomingRequest request;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;

    return ColoredBox(
      color: context.palette.background,
      child: SafeArea(
        child: MirrorMessage(
          icon: LucideIcons.screenShare,
          tone: .accent,
          title: l10n.allowTitle(request.deviceName),
          body: l10n.allowBody,
          actionLabel: l10n.allow,
          onAction: () => viewModel.answer(request, allow: true),
          secondLabel: l10n.dontAllow,
          onSecond: () => viewModel.answer(request, allow: false),
        ),
      ),
    );
  }
}
