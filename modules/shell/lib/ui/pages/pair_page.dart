import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/pages/other_ways_page.dart';
import 'package:shell/ui/pages/qr_pair_page.dart';
import 'package:shell/ui/pages/scan_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Add a device, least effort first: the ones nearby, each with a Pair
/// button; what to check when it isn't listed; then a QR code, and the
/// other ways (a link, an address) one level down.
class PairPage extends StatefulWidget {
  const PairPage({super.key, this.link});

  /// A pairing link read from a QR code before this page opened. Pairing
  /// with it starts right away.
  final String? link;

  @override
  State<PairPage> createState() => _PairPageState();
}

class _PairPageState extends State<PairPage> {
  late final PairingViewModel _viewModel = PairingViewModel(
    ShellScope.read(context).featureContext.engine,
  );

  @override
  void initState() {
    super.initState();
    if (widget.link case final link?) {
      _viewModel.pairWithLink(link);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final isIphone = defaultTargetPlatform == .iOS;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PairedCloser(
        viewModel: _viewModel,
        child: FerretPage(
          title: l10n.pairTitle,
          backLabel: l10n.back,
          width: .narrow,
          children: [
            const PairingStatusCard(),
            const NearbyFrame(),
            if (isIphone) ...[
              NearbyNotice(
                body: l10n.pairIphoneBody,
                actionLabel: l10n.scanButtonShort,
                onAction: () => unawaited(_pairWithQr()),
                isPrimary: true,
              ),
              Spacing.v16,
              GroupedCard(
                children: [
                  NavRow(
                    title: l10n.pairEnterCode,
                    onTap: () => _open(const OtherWaysPage()),
                  ),
                ],
              ),
            ],
            if (!isIphone) ...[
              SectionTitle(
                l10n.addDontSee,
                trailing: TextLink(
                  label: l10n.settingsCheckNetwork,
                  onTap: () => _open(const DoctorPage()),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
                child: Text(
                  l10n.pairCantSeeSteps,
                  style: typography.base2.copyWith(color: palette.mutedText),
                ),
              ),
              Spacing.v16,
              GroupedCard(
                children: [
                  NavRow(title: l10n.pairShowCode, onTap: _pairWithQr),
                  NavRow(
                    title: l10n.pairEnterCode,
                    onTap: () => _open(const OtherWaysPage()),
                  ),
                ],
              ),
            ],
            Spacing.v16,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.addShowsAs(engine.device.name),
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                      overflow: .ellipsis,
                    ),
                  ),
                  Spacing.h12,
                  TextLink(label: l10n.settingsRename, onTap: _rename),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A phone scans the computer's code; anything else shows its own.
  Future<void> _pairWithQr() async {
    final isPhone = switch (defaultTargetPlatform) {
      .android || .iOS => true,
      _ => false,
    };
    if (!isPhone) {
      _open(const QrPairPage());
      return;
    }

    final link = await Navigator.of(context).push<String>(
      ferretRoute<String>(const ScanPage()),
    );
    if (link == null) {
      return;
    }

    _viewModel.pairWithLink(link);
  }

  Future<void> _rename() async {
    final engine = ShellScope.read(context).featureContext.engine;

    await ThisDeviceCard.rename(context, engine);
    if (mounted) {
      setState(() {});
    }
  }

  void _open(Widget page) {
    unawaited(
      Navigator.of(
        context,
      ).push(ferretRoute<void>(page)),
    );
  }
}
