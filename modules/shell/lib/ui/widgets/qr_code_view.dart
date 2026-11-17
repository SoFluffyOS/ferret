import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// [data] as a QR code on a light tile, so it scans in dark mode too.
class QrCodeView extends StatelessWidget {
  const QrCodeView({super.key, required this.data});

  final String data;

  static const _ink = Color(0xFF111111);
  static const _paper = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(Spacing.d16),
        ),
        child: Padding(
          padding: EdgeInsets.all(Spacing.d16),
          child: QrImageView(
            data: data,
            size: Spacing.d200,
            backgroundColor: _paper,
            eyeStyle: const QrEyeStyle(eyeShape: .square, color: _ink),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: .square,
              color: _ink,
            ),
          ),
        ),
      ),
    );
  }
}
