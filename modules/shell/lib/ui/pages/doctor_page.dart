import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/connect_page.dart';
import 'package:shell/ui/pages/device_vpn_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Fix connection: explains why a paired device isn't connected, with fixes
/// as buttons. With no device, it checks this device's own network, for
/// when the device to pair doesn't show up.
class DoctorPage extends StatefulWidget {
  const DoctorPage({super.key, this.deviceId, this.doctorFor});

  final String? deviceId;

  /// Builds the checks for an engine; the real network when null. Lets a
  /// test stand in for a network that keeps devices apart.
  final ConnectionDoctor Function(FerretEngine engine)? doctorFor;

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
    final engine = ShellScope.read(context).featureContext.engine;
    _doctor = switch (widget.doctorFor) {
      final doctorFor? => doctorFor(engine),
      null => ConnectionDoctor(engine),
    };
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
    final realFixes = [
      for (final fix in fixes)
        if (!_quietFixes.contains(fix)) fix,
    ];
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
                  message: _describe(
                    l10n,
                    check,
                    name ?? '',
                    engine.device,
                    isolated: _checks.any((check) => check.kind == .isolated),
                  ),
                ),
              if (name == null && networkIsFine && _checks.isNotEmpty)
                DoctorCheckRow(
                  status: .ok,
                  message: l10n.doctorNetworkAllGood(here),
                ),
            ],
          ),
        ),
        if (_checks.any((check) => check.kind == .isolated)) ...[
          Spacing.v12,
          Text(
            _hotspotLine(l10n, engine),
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
        ],
        Spacing.v16,
        for (final (index, fix) in realFixes.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d8),
            child: Button(
              variant: switch (index) {
                0 => .primary,
                _ => .ghost,
              },
              label: _fixLabel(l10n, fix),
              onPressed: () => _apply(fix),
            ),
          ),
        _tryAgainAndLinks(
          tryAgain: Button(
            variant: switch (realFixes.isEmpty) {
              true => .primary,
              false => .ghost,
            },
            mainAxisSize: switch (_isTouch) {
              true => .max,
              false => .min,
            },
            label: l10n.doctorTryAgainPrimary,
            onPressed: _run,
          ),
          links: [
            for (final fix in [
              if (fixes.contains(DoctorFix.connectByAddress))
                DoctorFix.connectByAddress,
              DoctorFix.copyDiagnostics,
            ])
              Tappable(
                onTap: () => _apply(fix),
                child: Padding(
                  padding: EdgeInsets.all(Spacing.d8),
                  child: Text(
                    _fixLabel(l10n, fix),
                    style: typography.base2.copyWith(color: palette.link),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Phones stretch the button and center the quiet links under it; a
  /// pointer gets them on one row, next to the button.
  static bool get _isTouch => switch (defaultTargetPlatform) {
    .android || .iOS => true,
    _ => false,
  };

  Widget _tryAgainAndLinks({
    required Widget tryAgain,
    required List<Widget> links,
  }) {
    if (_isTouch) {
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          tryAgain,
          Spacing.v8,
          Wrap(alignment: .center, children: links),
        ],
      );
    }

    return Wrap(
      spacing: Spacing.d8,
      runSpacing: Spacing.d8,
      crossAxisAlignment: .center,
      children: [tryAgain, ...links],
    );
  }

  /// Fixes for what is actually wrong, as buttons. Connect by address and
  /// Copy diagnostics are for whoever helps, so they stay quiet links.
  static const _quietFixes = {
    DoctorFix.tryAgain,
    DoctorFix.connectByAddress,
    DoctorFix.copyDiagnostics,
  };

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
      case .allowFirewall:
        await _doctor.allowThroughFirewall();
        if (mounted) {
          _run();
        }
      case .openFirewall:
        await WindowsFirewall.openAllowedApps();
      case .copyFirewallCommand:
        await _copyFirewallCommand();
      case .copyDiagnostics:
        await _copy();
      case .reachOverVpn:
        if (widget.deviceId case final deviceId?) {
          await Navigator.of(context).push(
            ferretRoute<void>(DeviceVpnPage(deviceId: deviceId)),
          );
          _run();
        }
    }
  }

  Future<void> _copyFirewallCommand() async {
    final kind = _linuxFirewallOf(_checks);
    if (kind == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: kind.allowCommand));
  }

  static LinuxFirewallKind? _linuxFirewallOf(List<DoctorCheck> checks) {
    for (final check in checks) {
      for (final kind in LinuxFirewallKind.values) {
        if (check.kind == .firewall && check.detail == kind.name) {
          return kind;
        }
      }
    }

    return null;
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _doctor.diagnostics(_checks)));
  }

  String _fixLabel(ShellLocalizations l10n, DoctorFix fix) => switch (fix) {
    .tryAgain => l10n.doctorFixTryAgain,
    .connectByAddress => l10n.doctorFixConnectByAddress,
    .pairAgain => l10n.doctorFixPairAgain,
    .allowFirewall => l10n.doctorFixAllowFirewall,
    .openFirewall => l10n.doctorFixOpenFirewall,
    .copyFirewallCommand => l10n.doctorFixCopyFirewallCommand,
    .copyDiagnostics => l10n.doctorFixCopy,
    .reachOverVpn => l10n.doctorFixReachOverVpn,
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
      (check) =>
          (check.kind == .network || check.kind == .mobileData) &&
          check.status == .problem,
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

  /// A phone's hotspot is a network that never keeps devices apart, so it
  /// names the phone to turn it on, when there is one.
  String _hotspotLine(ShellLocalizations l10n, FerretEngine engine) {
    final here = l10n.here(engine.device);
    final target = switch (widget.deviceId) {
      final deviceId? => engine.trustStore[deviceId],
      null => null,
    };
    final isPhoneHere = here == LocalNames.herePhone;
    if (isPhoneHere && target != null) {
      return l10n.doctorHotspotHere(engine.displayNameOf(target.id));
    }

    final phones = [
      ?target,
      for (final status in engine.devices) status.device,
    ].where((device) => device.formFactor == .FORM_FACTOR_PHONE);
    if (isPhoneHere || phones.isEmpty) {
      return l10n.doctorHotspotAny(here);
    }

    return l10n.doctorHotspot(engine.displayNameOf(phones.first.id), here);
  }

  String _describe(
    ShellLocalizations l10n,
    DoctorCheck check,
    String device,
    LocalDevice local, {
    required bool isolated,
  }) {
    final here = l10n.here(local);

    return switch ((check.kind, check.status)) {
      (.network, .problem) => l10n.doctorNetworkProblem(here),
      (.network, _) => l10n.doctorNetworkOk(here),
      (.mobileData, _) when device.isEmpty => l10n.doctorMobileDataAny(here),
      (.mobileData, .problem) => l10n.doctorMobileData(here, device),
      (.mobileData, _) => l10n.doctorMobileDataVpn(here, device),
      (.vpn, _) => l10n.doctorVpn(check.detail),
      (.vpnReach, .ok) => l10n.doctorVpnReachOn(device),
      (.vpnReach, _) => l10n.doctorVpnReachOff(device),
      (.port, _) => l10n.doctorPort(check.detail),
      (.firewall, _) when check.detail == LinuxFirewallKind.ufw.name =>
        l10n.doctorFirewallLinux('ufw'),
      (.firewall, _) when check.detail == LinuxFirewallKind.firewalld.name =>
        l10n.doctorFirewallLinux('firewalld'),
      (.firewall, .ok) => l10n.doctorFirewallAllowed,
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
      (.reachable, _) when isolated => l10n.doctorReachableProblem(device),
      (.reachable, _) =>
        '${l10n.doctorReachableProblem(device)}\n\n'
            '${l10n.doctorNotAnsweringSteps(device, here)}',
      (.accepted, .running) => l10n.doctorAcceptedRunning,
      (.accepted, .ok) => l10n.doctorAcceptedOk,
      (.accepted, _) => l10n.doctorAcceptedProblem(device, here),
      (.isolated, .problem) => l10n.doctorIsolated(
        device,
        here,
      ),
      (.isolated, _) => l10n.doctorIsolatedMaybe,
    };
  }
}
