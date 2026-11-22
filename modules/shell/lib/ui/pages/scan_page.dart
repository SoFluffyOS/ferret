import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Scans a pairing QR code with the camera and returns its link. Uses
/// zxing-cpp on the device: nothing leaves the phone. With the camera
/// turned off for Ferret it says so, with the way to Settings, instead of
/// an empty frame.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, @visibleForTesting this.cameraOff = false});

  /// Starts as if the camera were turned off for Ferret.
  final bool cameraOff;

  /// Whether [error], from starting the camera, means the person said no
  /// to it (now or before), rather than a camera that failed.
  static bool isCameraOff(Object? error) =>
      error != null && '$error'.contains('CameraAccess');

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  bool _done = false;
  bool _wrongCode = false;
  late bool _cameraOff = widget.cameraOff;

  /// A new reader after a trip to Settings, so it asks for the camera again.
  int _reader = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed && _cameraOff && !widget.cameraOff) {
      setState(() {
        _cameraOff = false;
        _reader++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final message = switch ((_cameraOff, _wrongCode)) {
      (true, _) => l10n.scanCameraOff,
      (_, true) => l10n.scanNotFerret,
      _ => l10n.scanBody,
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
        if (_cameraOff)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Button(
              variant: .primary,
              label: l10n.nearbyOpenSettings,
              mainAxisSize: .min,
              titleExpand: .shrink,
              onPressed: () => unawaited(_openSettings()),
            ),
          )
        else
          ClipRSuperellipse(
            borderRadius: Corners.radius(Corners.panel),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ReaderWidget(
                key: ValueKey(_reader),
                codeFormat: Format.qrCode,
                showFlashlight: false,
                showToggleCamera: false,
                showGallery: false,
                cropPercent: 0.7,
                onScan: _onScan,
                onControllerCreated: (_, error) {
                  if (ScanPage.isCameraOff(error) && mounted) {
                    setState(() => _cameraOff = true);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  /// iOS opens Ferret's own page in Settings by this link; Android its
  /// App info.
  Future<void> _openSettings() async {
    if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
      return;
    }

    await FerretSystem().openAppSettings();
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
