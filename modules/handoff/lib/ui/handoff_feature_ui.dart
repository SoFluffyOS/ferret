import 'dart:async';
import 'dart:io' as io;

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/services/services.dart';
import 'package:handoff/ui/dialogs/send_flows.dart';
import 'package:handoff/ui/frames/frames.dart';
import 'package:handoff/ui/handoff_activity.dart';
import 'package:handoff/ui/handoff_health.dart';
import 'package:handoff/ui/pages/device_picker_page.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Handoff: "Continue" lines in Activity, the card for a
/// browser asking to pair, "Send a link…" on each device, its settings, and
/// the platform hooks.
class HandoffFeatureUi extends FeatureUi {
  /// [browserBridge] says whether to host the browser extension's bridge;
  /// it defaults to desktops.
  factory HandoffFeatureUi({
    FerretHandoff? handoff,
    ActivityOpener? opener,
    bool? browserBridge,
    BrowserBridgeServer? browserServer,
  }) {
    final platform = handoff ?? FerretHandoff();
    final recent = RecentPublishes();
    final firstOpener = BrowserFirstOpener(
      fallback: opener ?? PlatformActivityOpener(handoff: platform),
    );
    final feature = HandoffFeature(opener: firstOpener);
    final browser = BrowserBridge(
      feature: feature,
      isSupported: browserBridge ?? _isDesktop(),
      server: browserServer,
      recentPublishes: recent,
    );
    firstOpener.browser = browser;
    return HandoffFeatureUi._(platform, feature, browser, recent);
  }

  HandoffFeatureUi._(this._handoff, this.feature, this.browser, this._recent);

  @override
  final HandoffFeature feature;

  /// The local bridge the browser extension talks to.
  final BrowserBridge browser;
  final FerretHandoff _handoff;
  final RecentPublishes _recent;
  late final FeatureChanges _changes = FeatureChanges(
    _merge([feature.changes, browser.changes]),
  );
  HandoffViewModel? _viewModel;
  AppLifecycleListener? _lifecycle;

  @override
  String get featureId => HandoffFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    HandoffLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories =>
      HandoffBridge.categories(handoffL10nForSystem());

  @override
  String title(BuildContext context) => context.handoffL10n.title;

  @override
  IconData get icon => LucideIcons.monitorSmartphone;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final viewModel = viewModelFor(context);
    await viewModel.bridge.start();
    await browser.start();
    if (!viewModel.supportsAssistant) {
      return;
    }

    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(viewModel.refreshAssistant()),
    );
    await viewModel.refreshAssistant();
  }

  @override
  Listenable get uiChanges => _changes;

  /// Only while a browser waits to be allowed. What other devices offer to
  /// continue here is in [activity].
  @override
  bool hasHomeCard(FeatureContext feature) => browser.pairRequests.isNotEmpty;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    final viewModel = viewModelFor(feature);

    return HandoffActivity.items(
      context.handoffL10n,
      this.feature.suggestions,
      onOpen: (suggestion) =>
          unawaited(HandoffActivity.open(context, viewModel, suggestion)),
      onDismiss: viewModel.dismiss,
    );
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModelFor(feature),
        child: const HandoffHomeFrame(),
      );

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (device.session?.supports(featureId) != true) {
      return const [];
    }

    final l10n = context.handoffL10n;
    final viewModel = viewModelFor(feature);
    return [
      FeatureAction(
        label: l10n.actionSendLink,
        icon: LucideIcons.link,
        onPressed: () =>
            unawaited(SendFlows.sendLink(context, viewModel, device)),
      ),
      if (viewModel.canSendCurrentPage)
        FeatureAction(
          label: l10n.actionSendCurrentPage,
          icon: LucideIcons.globe,
          onPressed: () =>
              unawaited(SendFlows.sendCurrentPage(context, viewModel, device)),
        ),
    ];
  }

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    return continueHealthOf(
      handoffL10nForSystem(),
      session: session,
      name: device.device.name,
      lastSendFailed: this.feature.lastSendFailed(device.device.id),
      opensAutomatically: this.feature.opensAutomatically,
    );
  }

  @override
  SettingsGroup get settingsGroup => .continueAndMedia;

  @override
  Widget buildSettings(BuildContext context, FeatureContext feature) =>
      _withViewModel(feature, const HandoffSettingsFrame());

  /// Continue sits with media; the browser extension, where this device
  /// can host it, sits with the other apps Ferret works with.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.handoffL10n;
    final clients = browser.clients;
    final hasBrowser = browser.isEnabled && clients.isNotEmpty;

    return [
      FeatureSettings(
        group: settingsGroup,
        title: l10n.title,
        child: buildSettings(context, feature),
        summary: continueSummaryOf(
          l10n,
          passiveEnabled: this.feature.passiveEnabled,
        ),
        isOn: this.feature.passiveEnabled,
      ),
      if (browser.isSupported)
        FeatureSettings(
          group: .otherApps,
          title: l10n.settingsBrowserBridge,
          child: _withViewModel(feature, const BrowserSettingsFrame()),
          summary: browserSummaryOf(
            l10n,
            isEnabled: browser.isEnabled,
            clients: clients,
          ),
          isOn: hasBrowser,
          needsAttention: hasBrowser && browser.state.status == .failed,
        ),
    ];
  }

  /// The view model is made when the frame is first shown, not when the
  /// shell only asks what the row says.
  Widget _withViewModel(FeatureContext feature, Widget frame) => Builder(
    builder: (_) => ChangeNotifierProvider.value(
      value: viewModelFor(feature),
      child: frame,
    ),
  );

  /// Stops listening, for tests and hot restarts.
  void dispose() {
    unawaited(browser.stop());
    _lifecycle?.dispose();
    _viewModel?.dispose();
    _changes.dispose();
  }

  /// The one view model, made the first time the app asks for anything.
  HandoffViewModel viewModelFor(FeatureContext context) {
    if (_viewModel case final viewModel?) {
      return viewModel;
    }

    final bridge = HandoffBridge(
      feature: feature,
      engine: context.engine,
      notifier: context.notifier,
      handoff: _handoff,
      pickDevice: (devices) =>
          context.push<String>(DevicePickerPage(devices: devices)),
      recentPublishes: _recent,
      browser: browser,
      reveal: context.reveal,
    );
    final viewModel = HandoffViewModel(
      feature: feature,
      bridge: bridge,
      handoff: _handoff,
      browser: browser,
    );
    _viewModel = viewModel;
    return viewModel;
  }

  static bool _isDesktop() =>
      io.Platform.isMacOS || io.Platform.isLinux || io.Platform.isWindows;

  static Stream<void> _merge(List<Stream<void>> sources) =>
      Stream<void>.multi((controller) {
        final subscriptions = [
          for (final source in sources) source.listen(controller.add),
        ];
        controller.onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
      }, isBroadcast: true);
}
