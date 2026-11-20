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
/// the phone's own camera. It says how it goes, and closes once paired. A
/// link cut short says so, with a way to scan the code in Ferret.
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

  late bool _isLink;

  @override
  void initState() {
    super.initState();
    _isLink = _viewModel.pairWithLink(widget.link);
  }

  void _pair(String link) =>
      setState(() => _isLink = _viewModel.pairWithLink(link));

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
          children: [
            if (!_isLink) const _NotALink(),
            const PairingStatusCard(),
            _ScanAgain(isLink: _isLink, onLink: _pair),
          ],
        ),
      ),
    );
  }
}

/// A link that isn't a whole pairing offer, such as one cut short.
class _NotALink extends StatelessWidget {
  const _NotALink();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: Spacing.d8, bottom: Spacing.d8),
    child: SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: Text(
        context.shellL10n.scanNotFerret,
        textAlign: .center,
        style: context.fluffyTheme.typography.base1.copyWith(
          color: context.palette.text,
        ),
      ),
    ),
  );
}

/// After a code that didn't work, such as an old one, or a link that
/// wasn't one, scanning the computer's code is the next step.
class _ScanAgain extends StatelessWidget {
  const _ScanAgain({required this.isLink, required this.onLink});

  final bool isLink;
  final ValueChanged<String> onLink;

  @override
  Widget build(BuildContext context) {
    final failed = context.select<PairingViewModel, bool>(
      (viewModel) => switch (viewModel.state) {
        PairingDone(outcome: PairingFailed()) => true,
        _ => false,
      },
    );
    if (isLink && !failed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d12),
      child: Button(
        variant: .primary,
        label: context.shellL10n.scanButtonShort,
        tooltip: context.shellL10n.scanButton,
        semanticLabel: context.shellL10n.scanButton,
        onPressed: () => unawaited(_scan(context)),
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final link = await Navigator.of(
      context,
    ).push<String>(ferretRoute<String>(const ScanPage()));
    if (link == null) {
      return;
    }

    onLink(link);
  }
}
