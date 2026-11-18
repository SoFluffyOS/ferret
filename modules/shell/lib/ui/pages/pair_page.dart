import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/nearby_frame.dart';
import 'package:shell/ui/pages/scan_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Adds a device: the ones near you first, each with a Pair button. The
/// QR code, a link and an address wait behind "Can't see your device?".
class PairPage extends StatefulWidget {
  const PairPage({super.key});

  @override
  State<PairPage> createState() => _PairPageState();
}

class _PairPageState extends State<PairPage> {
  late final PairingViewModel _viewModel;
  final TextEditingController _link = .new();
  final TextEditingController _address = .new();
  String? _linkError;

  @override
  void initState() {
    super.initState();
    _viewModel = PairingViewModel(
      ShellScope.read(context).featureContext.engine,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _link.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: FerretPage(
        title: l10n.pairTitle,
        backLabel: l10n.back,
        children: [
          const _PairingStatus(),
          const NearbyFrame(),
          CantSeeDevice(
            onOpened: () => unawaited(_viewModel.createOffer()),
            children: [
              if (_canScan) ...[
                SectionTitle(l10n.scanSection),
                Button(
                  variant: .ghost,
                  label: l10n.scanButton,
                  onPressed: _scan,
                ),
              ],
              SectionTitle(l10n.pairShowCode),
              const _OfferCard(),
              SectionTitle(l10n.pairEnterCode),
              InputText(
                controller: _link,
                label: l10n.pairLinkLabel,
                hintText: l10n.pairLinkHint,
                errorText: _linkError,
                onSubmitted: (_) => _pairWithLink(),
              ),
              Spacing.v12,
              InputText(
                controller: _address,
                label: l10n.pairAddressLabel,
                hintText: l10n.pairAddressHint,
                keyboardType: .url,
                onSubmitted: (_) => _pairWithAddress(),
              ),
              Spacing.v12,
              Button(
                variant: .ghost,
                label: l10n.pairConnect,
                onPressed: _connect,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _canScan => Platform.isAndroid || Platform.isIOS;

  Future<void> _scan() async {
    final link = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(pageBuilder: (_, _, _) => const ScanPage()),
    );
    if (link == null) {
      return;
    }

    _viewModel.pairWithLink(link);
  }

  void _connect() {
    if (_link.text.trim().isNotEmpty) {
      _pairWithLink();
      return;
    }

    _pairWithAddress();
  }

  void _pairWithLink() {
    final accepted = _viewModel.pairWithLink(_link.text);
    setState(() {
      _linkError = switch (accepted) {
        true => null,
        false => context.shellL10n.pairLinkInvalid,
      };
    });
  }

  void _pairWithAddress() => _viewModel.pairWithAddress(_address.text);
}

class _OfferCard extends StatelessWidget {
  const _OfferCard();

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

    if (offer == null) {
      return SurfaceCard(
        child: SizedBox(height: Spacing.d200, child: const LoadingBox()),
      );
    }

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: Column(
        children: [
          Text(
            l10n.pairShowCodeBody,
            textAlign: .center,
            style: typography.body2.copyWith(color: palette.mutedText),
          ),
          Spacing.v16,
          QrCodeView(data: offer.qrText),
          Spacing.v12,
          Text(
            l10n.pairExpiresIn(minutes),
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          Spacing.v12,
          Row(
            children: [
              Expanded(
                child: Button(
                  variant: .ghost,
                  label: l10n.pairCopyLink,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: offer.qrText)),
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Button(
                  variant: .ghost,
                  label: l10n.pairNewCode,
                  onPressed: () =>
                      context.read<PairingViewModel>().createOffer(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairingStatus extends StatelessWidget {
  const _PairingStatus();

  @override
  Widget build(BuildContext context) {
    final state = context.select<PairingViewModel, PairingState>(
      (viewModel) => viewModel.state,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    final Widget content = switch (state) {
      PairingIdle() => const SizedBox.shrink(),
      PairingConnecting() => Text(
        l10n.pairWaiting,
        style: typography.body2.copyWith(color: palette.mutedText),
      ),
      PairingComparing(:final code, :final confirmedHere) => Column(
        crossAxisAlignment: .stretch,
        children: [
          ComparisonCode(code: code),
          Spacing.v12,
          Text(
            switch (confirmedHere) {
              true => l10n.pairWaiting,
              false => l10n.pairCompareTitle,
            },
            textAlign: .center,
            style: typography.body2.copyWith(color: palette.mutedText),
          ),
          if (!confirmedHere) ...[
            Spacing.v12,
            Row(
              children: [
                Expanded(
                  child: Button(
                    variant: .ghost,
                    label: l10n.cancel,
                    onPressed: context.read<PairingViewModel>().cancel,
                  ),
                ),
                Spacing.h12,
                Expanded(
                  child: Button(
                    variant: .primary,
                    label: l10n.nearbyTheyMatch,
                    onPressed: context.read<PairingViewModel>().confirm,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      PairingDone(:final outcome) => Text(
        _describe(l10n, outcome),
        textAlign: .center,
        style: typography.base1.copyWith(
          color: switch (outcome) {
            Paired() => palette.success,
            PairingFailed() => palette.danger,
          },
        ),
      ),
    };

    if (state is PairingIdle) {
      return content;
    }

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: SurfaceCard(
        padding: EdgeInsets.all(Spacing.d16),
        child: content,
      ),
    );
  }

  String _describe(ShellLocalizations l10n, PairingOutcome outcome) =>
      switch (outcome) {
        Paired(:final device) => l10n.pairSuccess(device.name),
        PairingFailed(:final reason) => switch (reason) {
          .unreachable => l10n.pairFailedUnreachable,
          .rejected => l10n.pairFailedRejected,
          .expired => l10n.pairFailedExpired,
          .badProof => l10n.pairFailedBadProof,
          .wrongDevice => l10n.pairFailedWrongDevice,
          .timedOut => l10n.pairFailedTimedOut,
          .cancelled => l10n.pairFailedProtocol,
          .protocol => l10n.pairFailedProtocol,
        },
      };
}
