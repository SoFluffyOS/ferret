import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/device_access_page.dart';
import 'package:shell/ui/pages/device_vpn_page.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/pages/webcam_help_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final preferences = context.read<EngineHost>().preferences;
    final details = [
      DeviceNameCard(
        ownName: device.ownName,
        nickname: device.nickname,
        hasNamesake: device.sameNameTag != null,
        here: l10n.here(engine.device),
        isPinned: context.select<EngineHost, bool>(
          (host) => host.preferences.isPinned(deviceId),
        ),
        onRename: (name) => unawaited(engine.renameDevice(deviceId, name)),
        onPin: (pinned) =>
            unawaited(preferences.setPinned(deviceId, pinned: pinned)),
      ),
      Spacing.v8,
      GroupedCard(
        separatorIndent: NavRow.placeIndent,
        children: [
          NavRow(
            title: l10n.accessTitle(device.name),
            value: DeviceAccessPage.summary(
              context,
              scope.features,
              engine,
              deviceId,
            ),
            place: (icon: LucideIcons.shieldCheck, color: .green),
            onTap: () => Navigator.of(context).push(
              ferretRoute<void>(DeviceAccessPage(deviceId: deviceId)),
            ),
          ),
          NavRow(
            title: l10n.vpnRow,
            value: DeviceVpnPage.summary(context, device),
            place: (icon: LucideIcons.globe, color: .blue),
            onTap: () => Navigator.of(context).push(
              ferretRoute<void>(DeviceVpnPage(deviceId: deviceId)),
            ),
          ),
          if (WebcamHelpPage.fits(device, engine.device))
            NavRow(
              title: l10n.webcamRow(device.name),
              place: (icon: LucideIcons.webcam, color: .orange),
              onTap: () => Navigator.of(context).push(
                ferretRoute<void>(
                  WebcamHelpPage(
                    deviceName: device.name,
                    here: l10n.here(engine.device),
                  ),
                ),
              ),
            ),
        ],
      ),
      Spacing.v8,
      Disclosure(
        title: l10n.deviceDetails,
        children: [
          for (final line in _details(context, status)) _DetailLine(line),
        ],
      ),
      ForgetDeviceCard(
        deviceName: device.name,
        here: l10n.here(engine.device),
        sharedWithOthers:
            engine.sharesPairings && engine.trustStore.devices.length > 1,
        onForget: (scope) => unawaited(_forget(context, scope)),
      ),
    ];
    // Home shows what else could be set up; a window has no Home.
    final offers = [
      if (WindowLayout.splits(context)) ...[Spacing.v8, const OffersCard()],
    ];

    return FerretPage(
      title: '',
      backLabel: l10n.back,
      children: [
        DeviceNowFrame(deviceId: deviceId),
        SuccessorsFrame(deviceId: deviceId),
        if (status.versionMismatch case final mismatch?)
          TwoColumns(
            leading: [
              DeviceHeader(status: status),
              UpdateNeededCard(
                mismatch: mismatch,
                deviceName: device.name,
                here: l10n.here(engine.device),
                onGetUpdate: _updateSource(),
              ),
            ],
            trailing: [...offers, ...details],
          ),
        if (!status.isConnected && status.versionMismatch == null)
          FeatureChangesListener(
            features: scope.features,
            builder: (context) => _Offline(
              status: status,
              trailing: [...offers, ...details],
            ),
          ),
        if (status.isConnected)
          FeatureChangesListener(
            features: scope.features,
            builder: (context) => TwoColumns(
              leading: [
                DeviceHeader(status: status),
                _Actions(status: status),
                for (final feature in scope.features)
                  ?feature.buildDeviceGroup(
                    context,
                    scope.featureContext,
                    status,
                  ),
                _WhatWorks(status: status),
              ],
              trailing: [
                _May(status: status),
                ...offers,
                ...details,
              ],
            ),
          ),
      ],
    );
  }

  /// Desktop builds come from the release page; phones update from their
  /// store, so there is nothing to open there.
  VoidCallback? _updateSource() => switch (defaultTargetPlatform) {
    .macOS || .windows || .linux => () => unawaited(
      launchUrl(WhatsNew.releases),
    ),
    _ => null,
  };

  List<String> _details(BuildContext context, DeviceStatus status) {
    final device = status.device;
    final l10n = context.shellL10n;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return [
      if (device.nickname != null) l10n.deviceOwnName(device.ownName),
      l10n.deviceIdLine(DeviceIdentity.format(device.id)),
      if ((device.lastHost, device.lastPort) case (final host?, final port?))
        l10n.settingsAddress('$host:$port'),
      if (status.reachedOverVpn) l10n.deviceReachedOverVpn,
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

    final preferences = context.read<EngineHost>().preferences;

    await engine.unpair(deviceId, everywhere: scope == .everywhere);
    await preferences.forget(deviceId);
    // In a window this page is the pane's first one, and the device list
    // moves on to another device by itself.
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

/// An offline device: what features can still do with it, such as wake
/// it, and finding out why it isn't connected.
class _Offline extends StatelessWidget {
  const _Offline({required this.status, required this.trailing});

  final DeviceStatus status;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final featureContext = scope.featureContext;
    final l10n = context.shellL10n;
    final actions = [
      for (final feature in scope.features)
        ...feature.offlineActions(context, featureContext, status),
    ];
    final offlineStatus = scope.features
        .map(
          (feature) => feature.offlineStatus(context, featureContext, status),
        )
        .nonNulls
        .firstOrNull;

    return TwoColumns(
      leading: [
        DeviceHeader(status: status, offlineStatus: offlineStatus),
        if (actions.isNotEmpty) ...[
          DeviceActions(actions: actions, moreLabel: l10n.homeMore),
          Spacing.v8,
        ],
        Button(
          variant: switch (actions.isEmpty) {
            true => .primary,
            false => .ghost,
          },
          titleExpand: .shrink,
          label: l10n.deviceWhyLong,
          onPressed: () => Navigator.of(context).push(
            ferretRoute<void>(DoctorPage(deviceId: status.device.id)),
          ),
        ),
      ],
      trailing: trailing,
    );
  }
}

/// What to do with a connected device: the few things done most, then
/// "More". An action that only opens a section is left out where the device
/// list already shows that section.
class _Actions extends StatelessWidget {
  const _Actions({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final featureContext = scope.featureContext;
    final listed = switch (WindowLayout.splits(context)) {
      true => {
        for (final section in DeviceSections.of(
          context,
          scope.features,
          featureContext,
          status,
        ))
          section.id,
      },
      false => const <String>{},
    };
    final actions = DeviceActionUsage(featureContext.engine.settings).arrange(
      status.device.id,
      DeviceActionOrder.of([
        for (final feature in scope.features)
          ...feature.deviceActions(context, featureContext, status),
      ], listedSections: listed),
    );
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    // In a window Needs you sits above every page, and may hold the
    // filled button already.
    return DeviceActions(
      actions: actions,
      moreLabel: context.shellL10n.homeMore,
      hasPrimary:
          !WindowLayout.splits(context) ||
          !ActivityFeed.holdsPrimary(context, scope.features, featureContext),
      shown: switch (context.screenSize) {
        .small => 3,
        _ => 4,
      },
    );
  }
}

/// Every feature that can work with a connected device, and how it is
/// doing: working, off or broken.
class _WhatWorks extends StatelessWidget {
  const _WhatWorks({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final name = status.device.name;
    final health = [
      for (final feature in scope.features)
        if (feature.healthFor(scope.featureContext, status) case final health?)
          (feature.title(context), health),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.deviceWhatWorks(name)),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              if (health.isEmpty)
                Text(
                  l10n.deviceNothingWorks(name),
                  style: context.fluffyTheme.typography.base2.copyWith(
                    color: context.palette.mutedText,
                  ),
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
      ],
    );
  }
}

/// What a connected device may do on this one, as switches.
class _May extends StatelessWidget {
  const _May({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final permissions = [
      for (final feature in scope.features)
        ...feature.devicePermissions(context, scope.featureContext, status),
    ];
    if (permissions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(context.shellL10n.deviceMay(status.device.name)),
        GroupedCard(
          children: [
            for (final permission in permissions)
              SettingSwitchRow(
                title: permission.label,
                body: switch (permission.detail) {
                  '' => null,
                  final detail => detail,
                },
                value: permission.value,
                onChanged: permission.onChanged,
              ),
          ],
        ),
      ],
    );
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
