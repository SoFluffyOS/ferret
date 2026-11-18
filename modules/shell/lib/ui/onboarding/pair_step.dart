import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/nearby_frame.dart';
import 'package:shell/ui/onboarding/onboarding_layout.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/pages/scan_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Pairs the first device: the ones near you show up by themselves, each
/// with a Pair button. Moves on as soon as a device pairs.
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
  bool _done = false;

  @override
  void initState() {
    super.initState();
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
        icon: LucideIcons.radar,
        title: l10n.onboardPairTitle,
        body: body,
        actions: [
          Button(
            variant: .ghost,
            label: l10n.onboardLater,
            onPressed: widget.onLater,
          ),
        ],
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            const NearbyFrame(),
            CantSeeDevice(
              onOpened: () => unawaited(_viewModel.createOffer()),
              children: [
                Spacing.v12,
                if (_isPhone)
                  Button(
                    variant: .ghost,
                    label: l10n.scanButton,
                    onPressed: _scan,
                  ),
                if (!_isPhone) const _Code(),
                Spacing.v8,
                Button(
                  variant: .ghost,
                  label: l10n.onboardMoreWays,
                  onPressed: _moreWays,
                ),
              ],
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
