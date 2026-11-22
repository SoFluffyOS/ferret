import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Shows this device's QR code for a phone to scan. Scanning proves the
/// phone is looking at this screen, so there is no code to compare.
class QrPairPage extends StatefulWidget {
  const QrPairPage({super.key});

  @override
  State<QrPairPage> createState() => _QrPairPageState();
}

class _QrPairPageState extends State<QrPairPage> {
  late final PairingViewModel _viewModel = PairingViewModel(
    ShellScope.read(context).featureContext.engine,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_viewModel.createOffer());
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
          title: l10n.pairShowCode,
          backLabel: l10n.back,
          width: .narrow,
          children: const [PairingStatusCard(), _QrCard()],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard();

  @override
  Widget build(BuildContext context) {
    final offer = context.select<PairingViewModel, PairingOfferHandle?>(
      (viewModel) => viewModel.offer,
    );
    final minutes = context.select<PairingViewModel, int>(
      (viewModel) => viewModel.minutesLeft,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final muted = typography.caption1.copyWith(color: palette.mutedText);

    if (offer == null) {
      return SurfaceCard(
        child: SizedBox(height: Spacing.d200, child: const LoadingBox()),
      );
    }

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: Column(
        children: [
          QrCodeView(data: offer.qrText, size: Spacing.d200 - Spacing.d20),
          Spacing.v16,
          Text(
            l10n.pairShowCodeBody,
            textAlign: .center,
            style: typography.base2.copyWith(color: palette.text),
          ),
          Spacing.v4,
          Text(l10n.qrScanEnough, textAlign: .center, style: muted),
          Spacing.v12,
          Text(
            '${l10n.qrWaiting} · ${l10n.pairExpiresIn(minutes)}',
            textAlign: .center,
            style: muted,
          ),
          Tappable(
            semanticButton: true,
            onTap: () =>
                unawaited(context.read<PairingViewModel>().createOffer()),
            child: Padding(
              padding: EdgeInsets.all(Spacing.d8),
              child: Text(
                l10n.pairNewCode,
                style: typography.base2.copyWith(color: palette.link),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
