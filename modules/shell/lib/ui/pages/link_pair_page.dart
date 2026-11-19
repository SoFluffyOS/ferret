import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/scan_page.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Pairs from a `ferret://pair` link: a computer's QR code scanned with
/// the phone's own camera. It says how it goes, and closes once paired.
class LinkPairPage extends StatefulWidget {
  const LinkPairPage({super.key, required this.link});

  final String link;

  @override
  State<LinkPairPage> createState() => _LinkPairPageState();
}

class _LinkPairPageState extends State<LinkPairPage> {
  late final PairingViewModel _viewModel = PairingViewModel(
    ShellScope.read(context).featureContext.engine,
  );

  @override
  void initState() {
    super.initState();
    _viewModel.pairWithLink(widget.link);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PairedCloser(
        viewModel: _viewModel,
        child: FerretPage(
          title: l10n.pairTitle,
          backLabel: l10n.back,
          width: .narrow,
          children: const [PairingStatusCard(), _ScanAgain()],
        ),
      ),
    );
  }
}

/// After a code that didn't work, such as an old one, scanning the
/// computer's new code is the next step.
class _ScanAgain extends StatelessWidget {
  const _ScanAgain();

  @override
  Widget build(BuildContext context) {
    final failed = context.select<PairingViewModel, bool>(
      (viewModel) => switch (viewModel.state) {
        PairingDone(outcome: PairingFailed()) => true,
        _ => false,
      },
    );
    if (!failed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d12),
      child: Button(
        variant: .primary,
        label: context.shellL10n.scanButton,
        onPressed: () => unawaited(_scan(context)),
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final viewModel = context.read<PairingViewModel>();
    final link = await Navigator.of(
      context,
    ).push<String>(ferretRoute<String>(const ScanPage()));
    if (link == null) {
      return;
    }

    viewModel.pairWithLink(link);
  }
}
