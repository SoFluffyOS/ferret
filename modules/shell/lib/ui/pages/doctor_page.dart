import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/connect_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Fix connection: explains why a paired device isn't connected, with fixes
/// as buttons. With no device, it checks this device's own network, for
/// when the device to pair doesn't show up.
class DoctorPage extends StatefulWidget {
  const DoctorPage({super.key, this.deviceId});

  final String? deviceId;

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  late final ConnectionDoctor _doctor;
  StreamSubscription<List<DoctorCheck>>? _subscription;
  List<DoctorCheck> _checks = const [];

  @override
  void initState() {
    super.initState();
    _doctor = ConnectionDoctor(ShellScope.read(context).featureContext.engine);
    _run();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _run() {
    unawaited(_subscription?.cancel());
    setState(() => _checks = const []);
    _subscription = _doctor
        .diagnose(widget.deviceId)
        .listen((checks) => setState(() => _checks = checks));
  }

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final name = _deviceName(engine);
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final here = l10n.here(engine.device);
    final fixes = {for (final check in _checks) ...check.fixes};
    final networkIsFine = _shown(
      _checks,
    ).every((check) => check.status == .ok);

    return FerretPage(
      title: l10n.doctorTitle,
      backLabel: l10n.back,
      children: [
        Text(
          switch (name) {
            final name? => l10n.doctorIntro(name),
            null => l10n.doctorNetworkIntro(here),
          },
          style: typography.body2.copyWith(color: palette.mutedText),
        ),
        Spacing.v12,
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              for (final check in _shown(_checks))
                DoctorCheckRow(
                  status: switch (_isUnknownAddress(check)) {
                    true => DoctorStatus.warning,
                    false => check.status,
                  },
                  message: _describe(l10n, check, name ?? '', engine.device),
                ),
              if (name == null && networkIsFine && _checks.isNotEmpty)
                DoctorCheckRow(
                  status: .ok,
                  message: l10n.doctorNetworkAllGood(here),
                ),
            ],
          ),
        ),
        Spacing.v16,
        Button(
          variant: .primary,
          label: l10n.doctorTryAgainPrimary,
          onPressed: _run,
        ),
        Spacing.v8,
        for (final fix in fixes.where((fix) => fix != .tryAgain))
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d8),
            child: Button(
              variant: .ghost,
              label: _fixLabel(l10n, fix),
              onPressed: () => _apply(fix),
            ),
          ),
        Button(variant: .ghost, label: l10n.doctorFixCopy, onPressed: _copy),
      ],
    );
  }

  Future<void> _apply(DoctorFix fix) async {
    switch (fix) {
      case .tryAgain:
        _run();
      case .connectByAddress:
        await Navigator.of(context).push(
          ferretRoute<void>(const ConnectPage()),
        );
        _run();
      case .pairAgain:
        await Navigator.of(context).push(
          ferretRoute<void>(const PairPage()),
        );
      case .openFirewall:
        await WindowsFirewall.openAllowedApps();
      case .copyDiagnostics:
        await _copy();
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _doctor.diagnostics(_checks)));
  }

  String _fixLabel(ShellLocalizations l10n, DoctorFix fix) => switch (fix) {
    .tryAgain => l10n.doctorFixTryAgain,
    .connectByAddress => l10n.doctorFixConnectByAddress,
    .pairAgain => l10n.doctorFixPairAgain,
    .openFirewall => l10n.doctorFixOpenFirewall,
    .copyDiagnostics => l10n.doctorFixCopy,
  };

  /// Ferret never heard where this device is, so there was nothing to
  /// knock on.
  bool _isUnknownAddress(DoctorCheck check) =>
      check.kind == .reachable &&
      check.status == .problem &&
      check.detail.isEmpty;

  /// The port line is for the copied diagnostics only, and "open Ferret on
  /// the other device" is no help while this device has no network.
  List<DoctorCheck> _shown(List<DoctorCheck> checks) {
    final offline = checks.any(
      (check) => check.kind == .network && check.status == .problem,
    );

    return [
      for (final check in checks)
        if (check.kind != .port && !(offline && _isUnknownAddress(check)))
          check,
    ];
  }

  String? _deviceName(FerretEngine engine) {
    final deviceId = widget.deviceId;
    if (deviceId == null) {
      return null;
    }

    return engine.trustStore[deviceId]?.name;
  }

  String _describe(
    ShellLocalizations l10n,
    DoctorCheck check,
    String device,
    LocalDevice local,
  ) {
    final here = l10n.here(local);

    return switch ((check.kind, check.status)) {
      (.network, .problem) => l10n.doctorNetworkProblem(l10n.hereStart(local)),
      (.network, _) => l10n.doctorNetworkOk(l10n.hereStart(local)),
      (.vpn, _) => l10n.doctorVpn(check.detail),
      (.port, _) => l10n.doctorPort(check.detail),
      (.firewall, _) => l10n.doctorFirewall,
      (.sameNetwork, .ok) => l10n.doctorSameNetworkOk(device, here),
      (.sameNetwork, _) => l10n.doctorSameNetworkWarning(
        device,
        check.detail,
        here,
      ),
      (.reachable, .running) => l10n.doctorReachableRunning(device),
      (.reachable, .ok) => l10n.doctorReachableOk(device),
      (.reachable, _) when check.detail.isEmpty => l10n.doctorNothingWrong(
        here,
        device,
      ),
      (.reachable, _) =>
        '${l10n.doctorReachableProblem(device)}\n\n'
            '${l10n.doctorNotAnsweringSteps(device, here)}',
      (.accepted, .running) => l10n.doctorAcceptedRunning,
      (.accepted, .ok) => l10n.doctorAcceptedOk,
      (.accepted, _) => l10n.doctorAcceptedProblem(device, here),
    };
  }
}
