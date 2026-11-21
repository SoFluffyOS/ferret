import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/activity_factory.dart';
import 'package:handoff/services/browser/browser.dart';
import 'package:handoff/services/handoff_settings.dart';
import 'package:handoff/services/recent_publishes.dart';
import 'package:protocol/handoff.dart';

/// Picks the device to continue on when the share sheet didn't say.
typedef DevicePicker = Future<String?> Function(List<HandoffPeer> devices);

/// Connects Handoff to the rest of this device: notices for things that
/// arrive, the Android share target and assistant, and the macOS browser.
/// It also opens links that Drop's send picker hands over.
class HandoffBridge implements LinkOpener {
  HandoffBridge({
    required this.feature,
    required this.engine,
    required this.notifier,
    required this.handoff,
    required this.pickDevice,
    HandoffLocalizations Function()? strings,
    Future<void> Function(Duration timeout)? untilForeground,
    this.connectTimeout = const Duration(seconds: 20),
    RecentPublishes? recentPublishes,
    this.browser,
    Future<void> Function()? reveal,
  }) : _reveal = reveal ?? _noReveal,
       _recent = recentPublishes ?? RecentPublishes(),
       _strings = strings ?? handoffL10nForSystem,
       _untilForeground = untilForeground ?? _untilResumed;

  static const continueCategory = 'handoff.continue';
  static const openAction = 'open';
  static const dismissAction = 'dismiss';
  static const _noticePrefix = 'handoff.';
  static const _pairNoticePrefix = 'handoff.browser_pair.';

  final HandoffFeature feature;
  final FeatureHost engine;
  final LocalNotifier notifier;
  final FerretHandoff handoff;
  final DevicePicker pickDevice;
  final Duration connectTimeout;

  /// The browser extension bridge, whose pair requests get a notice.
  final BrowserBridge? browser;
  final Future<void> Function() _reveal;
  final Set<String> _pairNotices = {};
  final HandoffLocalizations Function() _strings;
  final Future<void> Function(Duration timeout) _untilForeground;
  final RecentPublishes _recent;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<String, Suggestion> _noticed = {};

  /// The notice action set, registered before the first notice.
  static List<NoticeCategory> categories(HandoffLocalizations strings) => [
    NoticeCategory(
      id: continueCategory,
      actions: [
        NoticeAction(id: openAction, label: strings.open, opensApp: true),
        NoticeAction(id: dismissAction, label: strings.dismiss),
      ],
    ),
  ];

  static String noticeIdFor(String activityId) => '$_noticePrefix$activityId';

  bool get browserTabEnabled =>
      engine.settings.get<bool>(HandoffSettings.browserTab) ??
      HandoffSettings.browserTabDefault;

  Future<void> start() async {
    _subscriptions
      ..add(feature.arrivals.listen(_showArrival))
      ..add(feature.removals.listen(_withdrawNotice))
      ..add(feature.autoOpened.listen(_confirmOpened))
      ..add(notifier.responses.listen(_onResponse))
      ..add(engine.sessionChanges.listen((_) => unawaited(_syncDevices())))
      ..add(engine.trustStore.changes.listen((_) => unawaited(_syncDevices())))
      ..add(handoff.browserDeactivated.listen(_onBrowserLeft));

    if (browser case final browser?) {
      _subscriptions
        ..add(browser.pairRequested.listen(_showPairRequest))
        ..add(browser.changes.listen((_) => unawaited(_withdrawPairNotices())));
    }

    handoff.listen(onShared);
    await _syncDevices();
    await refreshBrowserWatch();

    for (final item in await handoff.takePending()) {
      unawaited(onShared(item));
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  Future<void> setBrowserTabEnabled(bool enabled) async {
    await engine.settings.set(HandoffSettings.browserTab, enabled);
    await refreshBrowserWatch();
  }

  /// Sends [activity] to [deviceId], waiting a little for the device to
  /// connect, such as right after Ferret started from the share sheet.
  Future<SendOutcome> sendWhenConnected(
    String deviceId,
    Activity activity,
  ) async {
    if (engine.sessionFor(deviceId) == null) {
      await engine.sessionChanges
          .firstWhere((_) => engine.sessionFor(deviceId) != null)
          .timeout(connectTimeout, onTimeout: () => const <Session>[]);
    }

    return feature.sendTo(deviceId, activity);
  }

  @override
  bool canOpenOn(String deviceId) =>
      engine.sessionFor(deviceId)?.supports(HandoffFeature.featureId) ?? false;

  /// A link shared with Send with Ferret, picked to open on [deviceId]
  /// instead of arriving there as text.
  @override
  Future<void> open(String deviceId, String text) => onShared(
    SharedItem(
      origin: .shareSheet,
      text: text,
      targetDeviceId: deviceId,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  /// Something came from the share sheet or the assistant. Answers true
  /// once it reached the other device.
  Future<bool> onShared(SharedItem item) async {
    final strings = _strings();
    final activity = ActivityFactory.fromShared(item);
    if (activity == null) {
      await _notify(
        id: '${_noticePrefix}share',
        channel: .problems,
        title: strings.noticeNothingToSend,
      );
      return false;
    }

    final deviceId = item.targetDeviceId ?? await _chooseDevice();
    if (deviceId == null) {
      return false;
    }

    final outcome = await sendWhenConnected(deviceId, activity);
    final name = _nameOf(deviceId);
    final sent = outcome == .opened || outcome == .suggested;
    if (!sent) {
      await _notify(
        id: '${_noticePrefix}share',
        channel: .problems,
        title: strings.noticeNotSent(name),
        body: strings.noticeNotSentBody,
      );
      return false;
    }

    if (item.targetDeviceId == null) {
      await _notify(
        id: '${_noticePrefix}share',
        channel: .suggestions,
        title: strings.noticeSent(name),
        silent: true,
      );
    }

    return true;
  }

  Future<String?> _chooseDevice() async {
    final connected = [
      for (final session in engine.sessions)
        if (session.supports(HandoffFeature.featureId))
          HandoffPeer.fromInfo(
            session.remoteDeviceId,
            session.remoteDevice,
            name: engine.displayNameOf(session.remoteDeviceId),
          ),
    ];
    if (connected.length == 1) {
      return connected.single.id;
    }

    return pickDevice(connected);
  }

  Future<void> _showArrival(Suggestion suggestion) async {
    final strings = _strings();
    _noticed[suggestion.id] = suggestion;
    await _notify(
      id: noticeIdFor(suggestion.id),
      channel: .suggestions,
      title: strings.noticeTitle(suggestion.activity.title),
      body: strings.noticeFrom(suggestion.from.name),
      category: continueCategory,
      groupKey: '$_noticePrefix${suggestion.from.id}',
    );
  }

  Future<void> _confirmOpened(TimelineEntry entry) async {
    if (entry.activity.kind != .ACTIVITY_KIND_TEXT) {
      return;
    }

    await _notify(
      id: noticeIdFor(entry.activity.id),
      channel: .suggestions,
      title: _strings().noticeTextCopied(entry.peer.name),
      silent: true,
    );
  }

  Future<void> _withdrawNotice(Suggestion suggestion) async {
    if (_noticed.remove(suggestion.id) == null) {
      return;
    }

    await notifier.cancel(noticeIdFor(suggestion.id));
  }

  Future<void> _onResponse(NoticeResponse response) async {
    if (response.noticeId.startsWith(_pairNoticePrefix)) {
      await _reveal();
      return;
    }

    if (!response.noticeId.startsWith(_noticePrefix)) {
      return;
    }

    final activityId = response.noticeId.substring(_noticePrefix.length);
    final suggestion = _noticed[activityId];
    if (suggestion == null) {
      return;
    }

    if (response.actionId == dismissAction) {
      feature.dismiss(activityId);
      return;
    }

    var result = await feature.open(suggestion);
    if (result == .deferred) {
      await _untilForeground(const Duration(seconds: 5));
      result = await feature.open(suggestion);
    }

    if (result == .failed) {
      await _notify(
        id: noticeIdFor(activityId),
        channel: .problems,
        title: _strings().openFailed,
      );
    }
  }

  /// A browser asked to pair: the user is at their browser right now, so
  /// Ferret comes forward with the prompt, and a notice says why.
  Future<void> _showPairRequest(BrowserPairRequest request) async {
    final strings = _strings();
    final id = '$_pairNoticePrefix${request.id}';
    _pairNotices.add(id);
    await _notify(
      id: id,
      channel: .incoming,
      title: strings.browserPairTitle(request.browser),
      body: strings.noticeBrowserPairBody(request.spacedCode),
    );
    await _reveal();
  }

  Future<void> _withdrawPairNotices() async {
    final pending = {
      for (final request in browser?.pairRequests ?? const [])
        '$_pairNoticePrefix${request.id}',
    };
    final answered = _pairNotices.difference(pending);
    for (final id in answered) {
      _pairNotices.remove(id);
      await notifier.cancel(id);
    }
  }

  static Future<void> _noReveal() async {}

  Future<void> _syncDevices() async {
    final connected = {
      for (final session in engine.sessions) session.remoteDeviceId,
    };
    final devices = [...engine.trustStore.devices]
      ..sort((first, second) {
        final firstRank = switch (connected.contains(first.id)) {
          true => 0,
          false => 1,
        };
        final secondRank = switch (connected.contains(second.id)) {
          true => 0,
          false => 1,
        };
        return firstRank.compareTo(secondRank);
      });

    try {
      await handoff.setDevices([
        for (final device in devices)
          HandoffDevice(id: device.id, name: device.name),
      ]);
    } on Object catch (error) {
      printWarning('Handoff could not share the device list', error);
    }
  }

  /// Watches the browser only while both the browser page and passive
  /// suggestions are on.
  Future<void> refreshBrowserWatch() async {
    if (!handoff.supportsBrowserTab) {
      return;
    }

    try {
      await handoff.setBrowserWatch(
        browserTabEnabled && feature.passiveEnabled,
      );
    } on Object catch (error) {
      printWarning('Handoff could not watch the browser', error);
    }
  }

  Future<void> _onBrowserLeft(String bundleId) async {
    if (!browserTabEnabled || !feature.passiveEnabled) {
      return;
    }

    try {
      final tab = await handoff.currentBrowserTab();
      if (tab == null || _recent.isRecent(tab.url, feature.passiveLifetime)) {
        return;
      }

      _recent.mark(tab.url);
      await feature.publish(ActivityFactory.fromBrowserTab(tab));
    } on Object catch (error) {
      printDebug('Handoff skipped the browser page (${error.runtimeType})');
    }
  }

  static Future<void> _untilResumed(Duration timeout) async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }

    final resumed = Completer<void>();
    final listener = AppLifecycleListener(onResume: resumed.complete);
    try {
      await resumed.future.timeout(timeout, onTimeout: () {});
    } finally {
      listener.dispose();
    }
  }

  String _nameOf(String deviceId) => engine.displayNameOf(deviceId);

  Future<void> _notify({
    required String id,
    required NoticeChannel channel,
    required String title,
    String body = '',
    String? category,
    String? groupKey,
    bool silent = false,
  }) async {
    try {
      await notifier.show(
        LocalNotice(
          id: id,
          channel: channel,
          title: title,
          body: body,
          category: category,
          groupKey: groupKey,
          silent: silent,
        ),
      );
    } on Object catch (error) {
      printWarning('Handoff could not show a notice', error);
    }
  }
}
