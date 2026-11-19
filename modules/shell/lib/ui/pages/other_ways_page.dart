import 'dart:async';
import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/paired_closer.dart';
import 'package:shell/ui/frames/pairing_status_card.dart';
import 'package:shell/ui/pages/qr_pair_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Pairing for when the devices can't see each other: a link to copy or
/// paste, and the other device's address. On a phone, also this phone's own
/// QR code, since its camera is the usual way.
class OtherWaysPage extends StatefulWidget {
  const OtherWaysPage({super.key});

  @override
  State<OtherWaysPage> createState() => _OtherWaysPageState();
}

class _OtherWaysPageState extends State<OtherWaysPage> {
  late final PairingViewModel _viewModel = PairingViewModel(
    ShellScope.read(context).featureContext.engine,
  );
  final TextEditingController _link = .new();
  final TextEditingController _address = .new();
  String? _linkError;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    unawaited(_viewModel.createOffer());
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
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final body = typography.base2.copyWith(color: palette.mutedText);

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PairedCloser(
        viewModel: _viewModel,
        child: FerretPage(
          title: l10n.pairEnterCode,
          backLabel: l10n.back,
          width: .narrow,
          children: [
            const PairingStatusCard(),
            SectionTitle(l10n.otherLinkTitle),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text(l10n.otherLinkBody, style: body),
                  Spacing.v12,
                  InputText(
                    controller: _link,
                    label: l10n.pairLinkLabel,
                    hintText: l10n.pairLinkHint,
                    errorText: _linkError,
                    onSubmitted: (_) => _pairWithLink(),
                  ),
                  Spacing.v12,
                  Wrap(
                    spacing: Spacing.d8,
                    runSpacing: Spacing.d8,
                    children: [
                      Button(
                        mainAxisSize: .min,
                        variant: .ghost,
                        label: l10n.otherPairLink,
                        onPressed: _pairWithLink,
                      ),
                      Button(
                        mainAxisSize: .min,
                        variant: .ghost,
                        label: switch (_copied) {
                          true => l10n.pairLinkCopied,
                          false => l10n.pairCopyLink,
                        },
                        onPressed: _copyLink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionTitle(l10n.otherAddressTitle),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text(l10n.otherAddressBody, style: body),
                  Spacing.v12,
                  InputText(
                    controller: _address,
                    label: l10n.pairAddressLabel,
                    hintText: l10n.pairAddressHint,
                    keyboardType: .url,
                    onSubmitted: (_) => _pairWithAddress(),
                  ),
                  Spacing.v12,
                  Wrap(
                    children: [
                      Button(
                        mainAxisSize: .min,
                        variant: .ghost,
                        label: l10n.otherPairAddress,
                        onPressed: _pairWithAddress,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (Platform.isAndroid || Platform.isIOS) ...[
              Spacing.v16,
              GroupedCard(
                children: [
                  NavRow(
                    title: l10n.otherShowQr,
                    onTap: () => Navigator.of(context).push(
                      ferretRoute<void>(
                        const QrPairPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyLink() async {
    final offer = _viewModel.offer;
    if (offer == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: offer.qrText));
    if (mounted) {
      setState(() => _copied = true);
    }
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
