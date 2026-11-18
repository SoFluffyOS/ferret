import 'dart:async';

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

/// Explains why a paired device isn't connected, with fixes as buttons.
class DoctorPage extends StatefulWidget {
  const DoctorPage({super.key, required this.deviceId});

  final String deviceId;

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
    final name = engine.trustStore[widget.deviceId]?.name ?? '';
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final fixes = {for (final check in _checks) ...check.fixes};

    return FerretPage(
      title: l10n.doctorTitle,
      backLabel: l10n.back,
      children: [
        Text(
          l10n.doctorIntro(name),
          style: typography.body2.copyWith(color: palette.mutedText),
        ),
        Spacing.v12,
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              for (final check in _checks.where((check) => check.kind != .port))
                DoctorCheckRow(
                  status: check.status,
                  message: _describe(l10n, check, name),
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
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => const ConnectPage()),
        );
        _run();
      case .pairAgain:
        await Navigator.of(context).push(
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => const PairPage()),
        );
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
    .copyDiagnostics => l10n.doctorFixCopy,
  };

  String _describe(
    ShellLocalizations l10n,
    DoctorCheck check,
    String device,
  ) => switch ((check.kind, check.status)) {
    (.network, .problem) => l10n.doctorNetworkProblem,
    (.network, _) => l10n.doctorNetworkOk,
    (.vpn, _) => l10n.doctorVpn(check.detail),
    (.port, _) => l10n.doctorPort(check.detail),
    (.sameNetwork, .ok) => l10n.doctorSameNetworkOk,
    (.sameNetwork, _) => l10n.doctorSameNetworkWarning(
      device,
      check.detail,
    ),
    (.reachable, .running) => l10n.doctorReachableRunning(device),
    (.reachable, .ok) => l10n.doctorReachableOk(device),
    (.reachable, _) =>
      '${l10n.doctorReachableProblem(device)}\n\n${l10n.doctorNotAnsweringSteps(device)}',
    (.accepted, .running) => l10n.doctorAcceptedRunning,
    (.accepted, .ok) => l10n.doctorAcceptedOk,
    (.accepted, _) => l10n.doctorAcceptedProblem(device),
  };
}
