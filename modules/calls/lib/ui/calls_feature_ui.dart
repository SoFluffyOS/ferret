import 'dart:async';

import 'package:calls/feature/calls_feature.dart';
import 'package:calls/l10n/l10n.dart';
import 'package:calls/services/services.dart';
import 'package:calls/ui/frames/frames.dart';
import 'package:calls/ui/pages/pages.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Calls: setup on the phone; on computers the incoming call
/// notice, the home card while a call rings or goes on, and "Call…".
class CallsFeatureUi extends FeatureUi {
  factory CallsFeatureUi() {
    if (!FerretCalls.isSupported) {
      return CallsFeatureUi.withFeature(CallsFeature());
    }

    return CallsFeatureUi.withFeature(CallsFeature(phone: FerretCalls()));
  }

  /// Uses [feature], such as one with a fake phone in tests.
  CallsFeatureUi.withFeature(this.feature);

  @override
  final CallsFeature feature;

  ActiveCallsViewModel? _activeCalls;
  CallNotices? _notices;

  @override
  String get featureId => CallsFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    CallsLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories => switch (feature.isPhone) {
    true => const [],
    false => CallNotices.categories(platformCallsL10n()),
  };

  @override
  String title(BuildContext context) => context.callsL10n.title;

  @override
  IconData get icon => LucideIcons.phone;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (feature.isPhone) {
      return;
    }

    // Recent calls show dates in the person's language.
    await initializeDateFormatting();
    _notices ??= CallNotices(
      control: feature,
      notifier: context.notifier,
      strings: platformCallsL10n,
    );
  }

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final flags = session.remoteFeature(featureId)?.flags ?? const <String>[];
    if (this.feature.isPhone) {
      return _phoneHealth(device, flags);
    }

    return _computerHealth(device, flags);
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (this.feature.isPhone) {
      return ChangeNotifierProvider(
        create: (_) => PhoneSetupViewModel(this.feature),
        child: PhoneHomeFrame(
          onSetUp: () => unawaited(
            feature.push<void>(PhoneSetupPage(feature: this.feature)),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _activeCalls ??= ActiveCallsViewModel(this.feature),
      child: const CallCardFrame(),
    );
  }

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    final flags = session?.remoteFeature(featureId)?.flags ?? const <String>[];
    if (this.feature.isPhone || !flags.contains(CallsFeature.phoneFlag)) {
      return const [];
    }

    return [
      FeatureAction(
        label: context.callsL10n.callAction,
        icon: LucideIcons.phoneOutgoing,
        onPressed: () => unawaited(
          feature.push<void>(
            DialerPage(
              control: this.feature,
              deviceId: device.device.id,
              deviceName: device.device.name,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    if (this.feature.isPhone) {
      return ChangeNotifierProvider(
        create: (_) => PhoneSetupViewModel(this.feature),
        child: const PhoneSetupFrame(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => CallsSettingsViewModel(this.feature),
      child: const CallsSettingsFrame(),
    );
  }

  /// Stops the notices and releases the home card's view model.
  Future<void> dispose() async {
    await _notices?.dispose();
    _activeCalls?.dispose();
  }

  /// On a computer, about a phone: what the phone last said it can do, or
  /// that it did not answer.
  FeatureHealth? _computerHealth(DeviceStatus device, List<String> flags) {
    if (!flags.contains(CallsFeature.phoneFlag)) {
      return null;
    }

    final link = feature.linkOf(device.device.id);
    if (link == null) {
      return null;
    }

    final l10n = platformCallsL10n();
    final name = device.device.name;
    final status = link.status;
    if (link.failed || status == null) {
      return FeatureHealth(.failing, reason: l10n.healthNoAnswer(name));
    }

    if (!status.enabled) {
      return FeatureHealth(.off, reason: l10n.healthOff(name));
    }

    if (!status.canSeeCalls) {
      return FeatureHealth(
        .needsAttention,
        reason: l10n.healthNeedsPermission(name),
      );
    }

    if (!status.canAnswer) {
      return FeatureHealth(.ok, reason: l10n.healthLimited(name));
    }

    return FeatureHealth(.ok, reason: l10n.healthOk(name));
  }

  /// On the phone, about a computer: whether calls are shared at all, and
  /// whether the last update reached it.
  FeatureHealth? _phoneHealth(DeviceStatus device, List<String> flags) {
    if (!flags.contains(CallsFeature.viewFlag)) {
      return null;
    }

    final l10n = platformCallsL10n();
    final name = device.device.name;
    if (!feature.settings.enabled) {
      return FeatureHealth(.off, reason: l10n.healthLocalOff);
    }

    if (!feature.isMonitoring) {
      return FeatureHealth(
        .needsAttention,
        reason: l10n.healthLocalNeedsPermission,
      );
    }

    if (feature.pushFailedTo(device.device.id)) {
      return FeatureHealth(.failing, reason: l10n.healthLocalPushFailed(name));
    }

    return FeatureHealth(.ok, reason: l10n.healthLocalOk(name));
  }
}
