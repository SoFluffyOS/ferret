import 'dart:async';

import 'package:calls/feature/calls_feature.dart';
import 'package:calls/l10n/l10n.dart';
import 'package:calls/services/services.dart';
import 'package:calls/ui/calls_activity.dart';
import 'package:calls/ui/frames/frames.dart';
import 'package:calls/ui/pages/pages.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/calls.dart' show CallLogEntry;
import 'package:protocol/protocol.dart' as proto;
import 'package:provider/provider.dart';

/// The app side of Calls: setup on the phone; on computers the incoming call
/// notice, the Activity line while a call rings or goes on, and "Call…".
class CallsFeatureUi extends FeatureUi {
  factory CallsFeatureUi() {
    if (!FerretCalls.isSupported) {
      return CallsFeatureUi.withFeature(CallsFeature());
    }

    return CallsFeatureUi.withFeature(CallsFeature(phone: FerretCalls()));
  }

  /// Uses [feature], such as one with a fake phone in tests.
  CallsFeatureUi.withFeature(this.feature);

  /// The id of the section a phone's dialer shows in.
  static const sectionId = 'calls';

  @override
  final CallsFeature feature;

  late final FeatureChanges _changes = FeatureChanges(feature.changes);

  /// The calls behind the Activity lines. It also fires when Answer or Hang
  /// up didn't work, which the feature's own changes don't tell.
  late final ActiveCallsViewModel _activeCalls = ActiveCallsViewModel(feature);
  late final Listenable _uiChanges = switch (feature.isPhone) {
    true => _changes,
    false => Listenable.merge([_changes, _activeCalls]),
  };
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
      onOpen: context.reveal,
    );
  }

  @override
  Listenable get uiChanges => _uiChanges;

  /// Only on the phone, while calls are on but Android hides them from
  /// Ferret. A computer shows its calls in [activity].
  @override
  bool hasHomeCard(FeatureContext feature) {
    if (!this.feature.isPhone) {
      return false;
    }

    final permissions = this.feature.permissions;
    final canSeeCalls = permissions?.phoneState ?? false;
    return this.feature.settings.enabled && permissions != null && !canSeeCalls;
  }

  /// On the phone, while calls are off.
  @override
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) {
    if (!this.feature.isPhone || this.feature.settings.enabled) {
      return null;
    }

    final l10n = context.callsL10n;
    return FeatureOffer(
      title: l10n.title,
      description: l10n.explainer,
      actionLabel: l10n.setUp,
      onAction: () => _openSetup(feature),
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
      return _phoneHealth(feature, device, flags);
    }

    return _computerHealth(device, flags);
  }

  /// On the phone, and on a computer once an Android phone is paired, under
  /// "To your computer" and "From your phone".
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.callsL10n;
    final state = switch (this.feature.isPhone) {
      true => _phoneSettingsState(l10n),
      false => _computerSettingsState(l10n, feature),
    };
    final child = buildSettings(context, feature);
    if (state == null || child == null) {
      return const [];
    }

    return [
      FeatureSettings(
        group: .phone,
        title: l10n.title,
        child: child,
        summary: state.summary,
        isOn: state.isOn,
        needsAttention: state.needsAttention,
      ),
    ];
  }

  @override
  SettingsGroup get settingsGroup => .phone;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (this.feature.isPhone) {
      return ChangeNotifierProvider(
        create: (_) => PhoneSetupViewModel(this.feature),
        child: PhoneHomeFrame(onSetUp: () => _openSetup(feature)),
      );
    }

    return ChangeNotifierProvider.value(
      value: _activeCalls,
      child: const CallCardFrame(),
    );
  }

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    if (this.feature.isPhone) {
      return const [];
    }

    return callsActivity(context.callsL10n, _activeCalls);
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
        id: 'calls.call',
        label: context.callsL10n.callAction,
        icon: LucideIcons.phoneOutgoing,
        onPressed: () =>
            unawaited(feature.openSection(device.device.id, sectionId)),
        sectionId: sectionId,
      ),
    ];
  }

  /// The recent calls each phone answered with last. In memory only: a
  /// call history is never written to this device.
  final Map<String, List<CallLogEntry>> _recentCalls = {};

  /// On a computer, the dialer and recent calls of a phone that can call,
  /// and of one that went offline after it showed them.
  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    final deviceId = device.device.id;
    final flags = session?.remoteFeature(featureId)?.flags ?? const <String>[];
    final canCall =
        flags.contains(CallsFeature.phoneFlag) ||
        _recentCalls.containsKey(deviceId);
    if (this.feature.isPhone || !canCall) {
      return const [];
    }

    return [
      FeatureSection(
        id: sectionId,
        title: title(context),
        icon: icon,
        order: 20,
        isSetUp: this.feature.linkOf(deviceId)?.status?.enabled ?? true,
        builder: (_) => DialerPage(
          control: this.feature,
          deviceId: deviceId,
          deviceName: device.device.name,
          lastLoaded: _recentCalls,
          activeCalls: _activeCalls,
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

  /// Stops the notices and releases the calls' view model.
  Future<void> dispose() async {
    await _notices?.dispose();
    _activeCalls.dispose();
    _changes.dispose();
  }

  void _openSetup(FeatureContext context) =>
      unawaited(context.push<void>(PhoneSetupPage(feature: feature)));

  /// On a computer, about a phone: what the phone last said it can do, or
  /// that it did not answer.
  FeatureHealth? _computerHealth(DeviceStatus device, List<String> flags) {
    if (!flags.contains(CallsFeature.phoneFlag)) {
      return null;
    }

    final l10n = platformCallsL10n();
    final deviceId = device.device.id;
    final link = feature.linkOf(deviceId);
    if (link == null) {
      return FeatureHealth(.off, reason: l10n.healthChecking);
    }

    final name = device.device.name;
    final status = link.status;
    if (link.failed || status == null) {
      return FeatureHealth(
        .failing,
        reason: l10n.healthNoAnswer(name),
        onFix: () => unawaited(feature.refreshStatus(deviceId)),
      );
    }

    if (!status.enabled) {
      return FeatureHealth(
        .off,
        reason: l10n.healthOff(name),
        help: l10n.healthOffHelp(name),
      );
    }

    if (!status.canSeeCalls) {
      return FeatureHealth(
        .needsAttention,
        reason: l10n.healthNeedsPermission,
        help: l10n.healthNeedsPermissionHelp(name),
      );
    }

    if (!status.canAnswer) {
      return FeatureHealth(.ok, reason: l10n.healthLimited(name));
    }

    return FeatureHealth(.ok, reason: l10n.healthOk);
  }

  /// On the phone, about a computer: whether calls are shared at all, and
  /// whether the last update reached it.
  FeatureHealth? _phoneHealth(
    FeatureContext context,
    DeviceStatus device,
    List<String> flags,
  ) {
    if (!flags.contains(CallsFeature.viewFlag)) {
      return null;
    }

    final l10n = platformCallsL10n();
    final name = device.device.name;
    if (!feature.settings.enabled) {
      return FeatureHealth(
        .off,
        reason: l10n.healthLocalOff,
        help: l10n.healthLocalOffHelp,
      );
    }

    if (!feature.isMonitoring) {
      return FeatureHealth(
        .needsAttention,
        reason: l10n.healthLocalNeedsPermission,
        onFix: () => _openSetup(context),
      );
    }

    if (feature.pushFailedTo(device.device.id)) {
      return FeatureHealth(
        .failing,
        reason: l10n.healthLocalPushFailed(name),
        help: l10n.healthLocalPushFailedHelp(name),
      );
    }

    return FeatureHealth(.ok, reason: l10n.healthLocalOk(name));
  }

  _SettingsState _phoneSettingsState(CallsLocalizations l10n) {
    final permissions = feature.permissions;
    if (!feature.settings.enabled) {
      return (summary: '', isOn: false, needsAttention: false);
    }

    if (permissions != null && !permissions.phoneState) {
      return (
        summary: l10n.settingsNeedsAccess,
        isOn: true,
        needsAttention: true,
      );
    }

    return (summary: '', isOn: true, needsAttention: false);
  }

  /// Null until an Android phone is paired: before that there is nothing
  /// to set. The phone that needs the person speaks first.
  _SettingsState? _computerSettingsState(
    CallsLocalizations l10n,
    FeatureContext context,
  ) {
    final settings = feature.settings;
    final phones = [
      for (final device in context.engine.trustStore.devices)
        if (device.platform == proto.Platform.PLATFORM_ANDROID) device,
    ];
    if (phones.isEmpty) {
      return null;
    }

    for (final device in phones) {
      final link = feature.linkOf(device.id);
      final status = link?.status;
      if (link == null) {
        continue;
      }

      if (link.failed && settings.wasSharing(device.id)) {
        return (
          summary: l10n.healthNoAnswer(device.name),
          isOn: true,
          needsAttention: true,
        );
      }

      if (status != null && status.enabled && !status.canSeeCalls) {
        return (
          summary: l10n.settingsNeedsAccessOn(device.name),
          isOn: true,
          needsAttention: true,
        );
      }
    }

    return (
      summary: '',
      isOn: phones.any((device) => settings.wasSharing(device.id)),
      needsAttention: false,
    );
  }
}

/// What the Settings row says about Calls.
typedef _SettingsState = ({String summary, bool isOn, bool needsAttention});
