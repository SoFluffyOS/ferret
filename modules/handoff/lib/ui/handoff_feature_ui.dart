import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/services/services.dart';
import 'package:handoff/ui/dialogs/send_flows.dart';
import 'package:handoff/ui/frames/frames.dart';
import 'package:handoff/ui/pages/device_picker_page.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Handoff: the "Continue" home card, "Send a link…" on
/// each device, its settings, and the platform hooks.
class HandoffFeatureUi extends FeatureUi {
  factory HandoffFeatureUi({FerretHandoff? handoff, ActivityOpener? opener}) {
    final platform = handoff ?? FerretHandoff();
    return HandoffFeatureUi._(
      platform,
      HandoffFeature(
        opener: opener ?? PlatformActivityOpener(handoff: platform),
      ),
    );
  }

  HandoffFeatureUi._(this._handoff, this.feature);

  @override
  final HandoffFeature feature;
  final FerretHandoff _handoff;
  late final FeatureChanges _changes = FeatureChanges(feature.changes);
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

  /// Only while another device offers something to continue here.
  @override
  bool hasHomeCard(FeatureContext feature) =>
      this.feature.suggestions.isNotEmpty;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModelFor(feature),
        child: const ContinueCardFrame(),
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
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModelFor(feature),
        child: const HandoffSettingsFrame(),
      );

  /// Stops listening, for tests and hot restarts.
  void dispose() {
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
    );
    final viewModel = HandoffViewModel(
      feature: feature,
      bridge: bridge,
      handoff: _handoff,
    );
    _viewModel = viewModel;
    return viewModel;
  }
}
