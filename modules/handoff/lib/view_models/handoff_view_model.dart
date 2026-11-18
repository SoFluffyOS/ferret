import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/services.dart';

/// Handoff's state for the home card, device actions and settings.
class HandoffViewModel extends ChangeNotifier {
  HandoffViewModel({
    required this.feature,
    required this.bridge,
    required this.handoff,
  }) {
    _subscriptions
      ..add(feature.changes.listen((_) => _refresh()))
      ..add(
        feature.host.settings.changes
            .where((key) => key.startsWith('${HandoffFeature.featureId}.'))
            .listen((_) => _refresh()),
      );
    _refresh();
  }

  final HandoffFeature feature;
  final HandoffBridge bridge;
  final FerretHandoff handoff;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<Suggestion> suggestions = const [];
  bool passiveEnabled = HandoffSettings.passiveDefault;
  bool opensAutomatically = HandoffSettings.openAutomaticallyDefault;
  bool browserTabEnabled = HandoffSettings.browserTabDefault;

  /// Null until asked, and on platforms without an assistant.
  bool? assistantEnabled;

  bool get supportsAssistant => handoff.supportsAssistant;

  bool get supportsBrowserTab => handoff.supportsBrowserTab;

  bool get canSendCurrentPage => supportsBrowserTab && browserTabEnabled;

  Future<OpenResult> open(Suggestion suggestion) => feature.open(suggestion);

  void dismiss(Suggestion suggestion) => feature.dismiss(suggestion.id);

  /// Sends a typed or pasted link (or plain text). Null when it was empty.
  Future<SendOutcome?> sendText(String deviceId, String text) async {
    final activity = ActivityFactory.fromText(text);
    if (activity == null) {
      return null;
    }

    return feature.sendTo(deviceId, activity);
  }

  Future<CurrentPageResult> sendCurrentPage(String deviceId) async {
    final BrowserTab? tab;
    try {
      tab = await handoff.currentBrowserTab();
    } on PlatformException catch (error) {
      return switch (error.code) {
        'denied' => const PageDenied(),
        'no-browser' => const PageMissing(),
        _ => const PageUnreadable(),
      };
    }

    if (tab == null || tab.url.isEmpty) {
      return const PageMissing();
    }

    final outcome = await feature.sendTo(
      deviceId,
      ActivityFactory.fromBrowserTab(tab),
    );
    return PageSent(outcome);
  }

  Future<void> setPassiveEnabled(bool enabled) async {
    await feature.setPassiveEnabled(enabled);
    await bridge.refreshBrowserWatch();
  }

  Future<void> setOpensAutomatically(bool enabled) =>
      feature.setOpensAutomatically(enabled);

  Future<void> setBrowserTabEnabled(bool enabled) async {
    await bridge.setBrowserTabEnabled(enabled);
    if (!enabled) {
      return;
    }

    try {
      final access = await handoff.browserAccess();
      if (access == .notDetermined) {
        await handoff.currentBrowserTab();
      }
    } on Object catch (error) {
      printDebug('Browser access check failed (${error.runtimeType})');
    }
  }

  Future<void> refreshAssistant() async {
    if (!supportsAssistant) {
      return;
    }

    try {
      assistantEnabled = await handoff.isAssistantEnabled();
    } on Object catch (error) {
      printWarning('Could not read the assistant setting', error);
      assistantEnabled = null;
    }

    notifyListeners();
  }

  Future<void> openAssistantSettings() => handoff.openAssistantSettings();

  void _refresh() {
    suggestions = feature.suggestions;
    passiveEnabled = feature.passiveEnabled;
    opensAutomatically = feature.opensAutomatically;
    browserTabEnabled = bridge.browserTabEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }
}
