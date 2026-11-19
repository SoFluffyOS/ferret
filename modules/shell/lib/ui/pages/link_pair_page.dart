import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/view_models/view_models.dart';

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
          children: const [PairingStatusCard()],
        ),
      ),
    );
  }
}
