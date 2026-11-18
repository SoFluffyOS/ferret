import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Scans a pairing QR code with the camera and returns its link. Uses
/// zxing-cpp on the device: nothing leaves the phone.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _done = false;
  bool _wrongCode = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final message = switch (_wrongCode) {
      true => l10n.scanNotFerret,
      false => l10n.scanBody,
    };

    return FerretPage(
      title: l10n.scanTitle,
      backLabel: l10n.back,
      children: [
        Text(
          message,
          style: typography.body2.copyWith(color: palette.mutedText),
        ),
        Spacing.v12,
        ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.d16),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ReaderWidget(
              codeFormat: Format.qrCode,
              showFlashlight: false,
              showToggleCamera: false,
              showGallery: false,
              cropPercent: 0.7,
              onScan: _onScan,
            ),
          ),
        ),
      ],
    );
  }

  void _onScan(Code code) {
    final text = code.text;
    if (_done || text == null) {
      return;
    }

    if (PairingCodes.parseOffer(text) == null) {
      setState(() => _wrongCode = true);
      return;
    }

    _done = true;
    Navigator.of(context).pop(text);
  }
}
