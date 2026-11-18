import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/onboarding/onboarding_layout.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/pages/scan_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Pairs the first device. Computers show a code to scan; phones scan the
/// computer's code. Moves on by itself as soon as a device pairs.
class PairStep extends StatefulWidget {
  const PairStep({
    super.key,
    required this.total,
    required this.engine,
    required this.onPaired,
    required this.onLater,
  });

  final int total;
  final FerretEngine engine;
  final ValueChanged<String> onPaired;
  final VoidCallback onLater;

  @override
  State<PairStep> createState() => _PairStepState();
}

class _PairStepState extends State<PairStep> {
  late final PairingViewModel _viewModel = PairingViewModel(widget.engine);
  late final StreamSubscription<List<DeviceStatus>> _devices;
  late final bool _isPhone = Platform.isAndroid || Platform.isIOS;
  late bool _showCode = !_isPhone;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    unawaited(_viewModel.createOffer());
    _devices = widget.engine.deviceChanges.listen(_onDevices);
  }

  @override
  void dispose() {
    unawaited(_devices.cancel());
    _viewModel.dispose();
    super.dispose();
  }

  void _onDevices(List<DeviceStatus> devices) {
    if (_done || devices.isEmpty) {
      return;
    }

    _done = true;
    widget.onPaired(devices.first.device.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final body = switch (_isPhone) {
      true => l10n.onboardPairBodyPhone,
      false => l10n.onboardPairBodyComputer,
    };

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: OnboardingLayout(
        step: 3,
        total: widget.total,
        icon: LucideIcons.qrCode,
        title: l10n.onboardPairTitle,
        body: body,
        actions: [
          if (_isPhone)
            Button(variant: .primary, label: l10n.scanButton, onPressed: _scan),
          Button(
            variant: .ghost,
            label: l10n.onboardMoreWays,
            onPressed: _moreWays,
          ),
          Button(
            variant: .ghost,
            label: l10n.onboardLater,
            onPressed: widget.onLater,
          ),
        ],
        child: Column(
          children: [
            if (_showCode) const _Code(),
            if (!_showCode)
              Button(
                variant: .secondary,
                label: l10n.onboardShowMyCode,
                onPressed: () => setState(() => _showCode = true),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _scan() async {
    final link = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(pageBuilder: (_, _, _) => const ScanPage()),
    );
    if (link == null) {
      return;
    }

    _viewModel.pairWithLink(link);
  }

  Future<void> _moreWays() async {
    await Navigator.of(
      context,
    ).push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => const PairPage()));
  }
}

class _Code extends StatelessWidget {
  const _Code();

  @override
  Widget build(BuildContext context) {
    final offer = context.select<PairingViewModel, PairingOfferHandle?>(
      (viewModel) => viewModel.offer,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    if (offer == null) {
      return SizedBox(height: Spacing.d200, child: const LoadingBox());
    }

    return Column(
      children: [
        QrCodeView(data: offer.qrText),
        Spacing.v12,
        Text(
          context.shellL10n.onboardPairWaiting,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
      ],
    );
  }
}
