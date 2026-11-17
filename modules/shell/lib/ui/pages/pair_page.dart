import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Pairs this device with another: show a QR code, or use a link or an
/// address.
class PairPage extends StatefulWidget {
  const PairPage({super.key, this.initialAddress});

  /// Starts pairing with this `host:port` right away, such as a nearby device.
  final String? initialAddress;

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
    unawaited(_viewModel.createOffer());

    if (widget.initialAddress case final address?) {
      _address.text = address;
      _viewModel.pairWithAddress(address);
    }
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
          SectionTitle(l10n.pairShowCode),
          const _OfferCard(),
          SectionTitle(l10n.pairEnterCode),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
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
                  variant: .primary,
                  label: l10n.pairConnect,
                  onPressed: _connect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  variant: .secondary,
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
      PairingComparing(:final code) => Column(
        children: [
          Text(
            l10n.pairCompareTitle,
            style: typography.title3.copyWith(color: palette.text),
          ),
          Spacing.v12,
          ComparisonCode(code: code),
          Spacing.v12,
          Text(
            l10n.pairWaiting,
            style: typography.body2.copyWith(color: palette.mutedText),
          ),
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
        child: Center(child: content),
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
          .protocol => l10n.pairFailedProtocol,
        },
      };
}
