import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/widgets/device_header.dart';
import 'package:shell/ui/widgets/disclosure.dart';
import 'package:shell/ui/widgets/forget_device_card.dart';
import 'package:shell/ui/widgets/health_row.dart';
import 'package:shell/ui/widgets/switch_row.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One paired device: whether it's connected, what to do with it, what
/// works with it (and what is off or broken), what it may do here, and
/// forgetting it.
class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final status = context.select<EngineHost, DeviceStatus?>(
      (host) => host.statusOf(deviceId),
    );
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;

    if (status == null) {
      return FerretPage(title: '', backLabel: l10n.back, children: const []);
    }

    final engine = scope.featureContext.engine;
    final device = status.device;

    return FerretPage(
      title: '',
      backLabel: l10n.back,
      children: [
        DeviceHeader(status: status),
        if (!status.isConnected)
          Button(
            variant: .primary,
            label: l10n.deviceWhyLong,
            onPressed: () => Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => DoctorPage(deviceId: deviceId),
              ),
            ),
          ),
        if (status.isConnected)
          FeatureChangesListener(
            features: scope.features,
            builder: (context) => _Connected(status: status),
          ),
        Spacing.v8,
        Disclosure(
          title: l10n.deviceDetails,
          children: [
            for (final line in _details(context, device)) _DetailLine(line),
          ],
        ),
        ForgetDeviceCard(
          deviceName: device.name,
          here: l10n.here(engine.device),
          sharedWithOthers:
              engine.sharesPairings && engine.trustStore.devices.length > 1,
          onForget: (scope) => unawaited(_forget(context, scope)),
        ),
      ],
    );
  }

  List<String> _details(BuildContext context, TrustedDevice device) {
    final l10n = context.shellL10n;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return [
      '${l10n.deviceTitleId} ${DeviceIdentity.format(device.id)}',
      if ((device.lastHost, device.lastPort) case (final host?, final port?))
        l10n.settingsAddress('$host:$port'),
      l10n.devicePairedOn(DateFormat.yMMMd(locale).format(device.pairedAt)),
      if (_introducerName(context, device) case final introducer?)
        l10n.devicePairedThrough(introducer),
    ];
  }

  /// The name of the device that vouched for [device], when it joined
  /// through another one and that one is still paired.
  String? _introducerName(BuildContext context, TrustedDevice device) {
    final introducedBy = device.introducedBy;
    if (introducedBy == null) {
      return null;
    }

    final engine = ShellScope.read(context).featureContext.engine;
    return engine.trustStore[introducedBy]?.name;
  }

  Future<void> _forget(BuildContext context, ForgetScope scope) async {
    final engine = ShellScope.read(context).featureContext.engine;
    final navigator = Navigator.of(context);

    await engine.unpair(deviceId, everywhere: scope == .everywhere);
    navigator.pop();
  }
}

/// What a connected device adds to its page: its actions, what works with
/// it, and what it may do here.
class _Connected extends StatelessWidget {
  const _Connected({required this.status});

  final DeviceStatus status;

  /// Sorts after every action that has a place on Home.
  static const _pageOnly = 1 << 20;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final name = status.device.name;
    final featureContext = scope.featureContext;
    final actions = [
      for (final feature in scope.features)
        ...feature.deviceActions(context, featureContext, status),
    ];
    final ordered = [
      for (final (index, action) in actions.indexed) (index, action),
    ]..sort(_byHomeOrder);
    final health = [
      for (final feature in scope.features)
        if (feature.healthFor(featureContext, status) case final health?)
          (feature.title(context), health),
    ];
    final permissions = [
      for (final feature in scope.features)
        ...feature.devicePermissions(context, featureContext, status),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (ordered.isNotEmpty)
          Wrap(
            spacing: Spacing.d8,
            runSpacing: Spacing.d8,
            children: [
              for (final (position, (_, action)) in ordered.indexed)
                Button(
                  variant: switch (position) {
                    0 => .primary,
                    _ => .ghost,
                  },
                  label: action.label,
                  icon: Icon(action.icon, size: Spacing.d16),
                  onPressed: action.onPressed,
                ),
            ],
          ),
        SectionTitle(l10n.deviceWhatWorks(name)),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              if (health.isEmpty)
                Text(
                  l10n.deviceNothingWorks(name),
                  style: typography.base2.copyWith(color: palette.mutedText),
                ),
              for (final (title, featureHealth) in health)
                HealthRow(
                  key: ValueKey(title),
                  title: title,
                  health: featureHealth,
                  howLabel: l10n.deviceHow,
                  fixLabel: l10n.deviceFix,
                ),
            ],
          ),
        ),
        if (permissions.isNotEmpty) ...[
          SectionTitle(l10n.deviceMay(name)),
          SurfaceCard(
            child: Column(
              children: [
                for (final (index, permission) in permissions.indexed) ...[
                  if (index > 0) Spacing.v12,
                  SwitchRow(
                    title: permission.label,
                    subtitle: switch (permission.detail) {
                      '' => null,
                      final detail => detail,
                    },
                    value: permission.value,
                    onChanged: permission.onChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Home's order first, then the order features gave them in.
  static int _byHomeOrder((int, FeatureAction) a, (int, FeatureAction) b) {
    final byOrder = (a.$2.homeOrder ?? _pageOnly).compareTo(
      b.$2.homeOrder ?? _pageOnly,
    );
    if (byOrder != 0) {
      return byOrder;
    }

    return a.$1.compareTo(b.$1);
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d4),
      child: Text(
        text,
        style: context.fluffyTheme.typography.caption1.copyWith(
          color: context.palette.mutedText,
        ),
      ),
    );
  }
}
