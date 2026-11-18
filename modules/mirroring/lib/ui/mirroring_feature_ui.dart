import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/ui/pages/pages.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The app side of Screen mirroring. On a computer: "Show screen" on each
/// Android phone, the mirror page, and a card while a phone is shown. On a
/// phone: the "Sharing screen with MacBook · Stop" card (next to Android's
/// own ongoing notice), the audit line, and Settings with the history.
class MirroringFeatureUi extends FeatureUi {
  /// [routes] and [receivers] are more ways a screen can arrive here,
  /// next to Ferret's own. They go to the feature this creates; a
  /// [feature] passed in brings its own.
  MirroringFeatureUi({
    MirroringFeature? feature,
    MirrorWindow? window,
    List<MirrorRoute> routes = const [],
    List<MirrorReceiver> receivers = const [],
  }) : feature =
           feature ?? MirroringFeature(routes: routes, receivers: receivers),
       _window = window {
    this.feature.texts = _noticeTexts;
  }

  @override
  final MirroringFeature feature;

  final MirrorWindow? _window;

  late final ViewerViewModel viewerViewModel = ViewerViewModel(
    feature,
    window: _window,
  );
  late final ShareViewModel shareViewModel = ShareViewModel(feature);
  late final FeatureChanges _changes = FeatureChanges(feature.changes);
  StreamSubscription<void>? _revealOnAsk;
  StreamSubscription<MirrorFeed>? _openOnIncoming;
  StreamSubscription<void>? _askOnRequest;
  final Set<IncomingRequest> _asked = {};

  /// When the request the app was last brought to the front for was made.
  DateTime? _revealedFor;

  @override
  String get featureId => MirroringFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MirroringLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.mirroringL10n.title;

  @override
  IconData get icon => LucideIcons.screenShare;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    _openOnIncoming = feature.routes?.incoming.listen(
      (feed) => unawaited(_openIncoming(context, feed.target)),
    );
    _askOnRequest = feature.changes.listen((_) => _askWhenRequested(context));
    if (feature.source == null) {
      return;
    }

    _revealOnAsk = feature.changes.listen((_) => _revealWhenAsked(context));
  }

  @override
  Listenable get uiChanges => _changes;

  /// Only while a screen is asked for or shown, or just was.
  @override
  bool hasHomeCard(FeatureContext feature) =>
      viewerViewModel.hasCard || shareViewModel.hasCard;

  /// The other ways to show a screen stay off until asked for.
  @override
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) {
    if (!viewerViewModel.hasMoreWays || viewerViewModel.moreWays) {
      return null;
    }

    final l10n = context.mirroringL10n;
    return FeatureOffer(
      title: l10n.title,
      description: l10n.moreWaysOffer,
      actionLabel: l10n.turnOn,
      onAction: () => unawaited(viewerViewModel.setMoreWays(true)),
    );
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (shareViewModel.isAvailable && shareViewModel.hasCard) {
      return ChangeNotifierProvider.value(
        value: shareViewModel,
        child: const ShareCardFrame(),
      );
    }

    if (!viewerViewModel.isAvailable) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: viewerViewModel,
      child: ViewerCardFrame(
        onOpen: (session) => unawaited(_openPage(feature, session.target)),
        onShow: (target) => unawaited(_showTarget(feature, target)),
      ),
    );
  }

  /// On a computer: whether [device] can show its screen here, from how
  /// the last try went. On a phone: whether [device] may ask to see it.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final l10n = platformMirroringL10n();
    if (this.feature.canViewDevice(session)) {
      return _viewerHealth(l10n, device.device);
    }

    if (shareViewModel.isAvailable && _isViewer(session)) {
      return _shareHealth(l10n, device.device);
    }

    return null;
  }

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    final label = context.mirroringL10n.showScreen;
    if (session != null && this.feature.canViewDevice(session)) {
      return [
        FeatureAction(
          label: label,
          icon: LucideIcons.screenShare,
          onPressed: () => unawaited(
            _openMirror(feature, device.device.id, device.device.name),
          ),
        ),
      ];
    }

    final target = viewerViewModel.targetForDevice(device.device.id);
    if (target == null) {
      return const [];
    }

    return [
      FeatureAction(
        label: label,
        icon: LucideIcons.screenShare,
        onPressed: () => unawaited(_showTarget(feature, target)),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final sections = [
      if (shareViewModel.isAvailable) _shareSettings(),
      if (viewerViewModel.isAvailable && _hasViewerSettings(feature))
        _viewerSettings(),
    ];
    if (sections.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, section) in sections.indexed) ...[
          if (index > 0) Spacing.v8,
          section,
        ],
      ],
    );
  }

  /// Screen sits with what a phone shares with a computer. A phone's part
  /// is on while computers may ask; a computer's part has no on and off,
  /// because the phone decides every time.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.mirroringL10n;
    final title = this.title(context);

    return [
      if (shareViewModel.isAvailable)
        FeatureSettings(
          group: .phone,
          title: title,
          child: _shareSettings(),
          summary: _shareSummary(l10n),
          isOn: shareViewModel.enabled && shareViewModel.canCapture,
        ),
      if (viewerViewModel.isAvailable && _hasViewerSettings(feature))
        FeatureSettings(
          group: .phone,
          title: title,
          child: _viewerSettings(),
          summary: switch (viewerViewModel.moreWays) {
            true => l10n.summaryMoreWays,
            false => '',
          },
        ),
    ];
  }

  /// On a phone, whether the computer [device] may ask to see its screen.
  @override
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final deviceId = device.device.id;
    final applies =
        _isViewer(device.session) || !shareViewModel.mayAsk(deviceId);
    if (!shareViewModel.isAvailable || !applies) {
      return const [];
    }

    final l10n = context.mirroringL10n;
    return [
      DevicePermission(
        label: l10n.permissionAsk,
        detail: switch (shareViewModel.enabled) {
          true => l10n.settingsAllowBody,
          false => l10n.permissionAskOff,
        },
        value: shareViewModel.mayAsk(deviceId),
        onChanged: (value) =>
            unawaited(shareViewModel.setMayAsk(deviceId, value)),
      ),
    ];
  }

  Widget _shareSettings() => ChangeNotifierProvider.value(
    value: shareViewModel,
    child: const ShareSettingsFrame(),
  );

  Widget _viewerSettings() => ChangeNotifierProvider.value(
    value: viewerViewModel,
    child: const ViewerSettingsFrame(),
  );

  /// A computer's part only helps once an Android phone is paired, to keep
  /// showing what it mirrored before, or once the other ways are on. Until
  /// then the other ways are an offer, not a setting.
  bool _hasViewerSettings(FeatureContext featureContext) =>
      viewerViewModel.moreWays ||
      viewerViewModel.history.isNotEmpty ||
      featureContext.engine.devices.any(
        (status) => status.device.platform == .PLATFORM_ANDROID,
      );

  /// Whether [session]'s device can show another's screen.
  bool _isViewer(Session? session) =>
      session
          ?.remoteFeature(featureId)
          ?.flags
          .contains(MirroringFeature.viewFlag) ??
      false;

  String _shareSummary(MirroringLocalizations l10n) {
    if (!shareViewModel.enabled) {
      return l10n.summaryOff;
    }

    if (!shareViewModel.canCapture) {
      return l10n.summaryCantCapture;
    }

    return l10n.summaryAsks;
  }

  FeatureHealth _viewerHealth(
    MirroringLocalizations l10n,
    TrustedDevice device,
  ) {
    final name = device.name;
    final current = feature.viewer?.current;
    if (current != null &&
        current.deviceId == device.id &&
        current.isMirroring) {
      return FeatureHealth(.ok, reason: l10n.healthViewing);
    }

    return switch (feature.viewer?.lastEndFor(device.id)) {
      .turnedOff => FeatureHealth(
        .off,
        reason: l10n.healthTurnedOff(name),
        help: l10n.endTurnedOffBody(name),
      ),
      .unsupported => FeatureHealth(.off, reason: l10n.healthUnsupported(name)),
      .cannotAsk => FeatureHealth(
        .needsAttention,
        reason: l10n.healthCannotAsk(name),
        help: l10n.endCannotAskBody(name),
      ),
      .failed => FeatureHealth(
        .failing,
        reason: l10n.healthFailed(name),
        help: l10n.healthTryAgainHelp,
      ),
      .decoderFailed => FeatureHealth(
        .failing,
        reason: l10n.healthDecoderFailed,
        help: l10n.healthTryAgainHelp,
      ),
      _ => FeatureHealth(.ok, reason: l10n.healthAsks(name)),
    };
  }

  FeatureHealth _shareHealth(
    MirroringLocalizations l10n,
    TrustedDevice device,
  ) {
    final name = device.name;
    if (!shareViewModel.enabled) {
      return FeatureHealth(
        .off,
        reason: l10n.healthShareOff,
        help: l10n.healthShareOffHelp,
      );
    }

    if (!shareViewModel.mayAsk(device.id)) {
      return FeatureHealth(
        .off,
        reason: l10n.healthShareBlocked(name),
        help: l10n.healthShareBlockedHelp(name),
      );
    }

    if (!shareViewModel.canCapture) {
      return FeatureHealth(.off, reason: l10n.settingsUnsupported);
    }

    if (shareViewModel.active?.deviceId == device.id) {
      return FeatureHealth(.ok, reason: l10n.healthSharing);
    }

    return FeatureHealth(.ok, reason: l10n.healthShareAsks);
  }

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _revealOnAsk?.cancel();
    await _openOnIncoming?.cancel();
    await _askOnRequest?.cancel();
    _changes.dispose();
    viewerViewModel.dispose();
    shareViewModel.dispose();
  }

  /// Brings Ferret to the front once per request, so the owner sees who
  /// is asking next to Android's prompt.
  void _revealWhenAsked(FeatureContext context) {
    final askedAt = feature.source?.pending?.askedAt;
    if (askedAt == null || _revealedFor == askedAt) {
      return;
    }

    _revealedFor = askedAt;
    unawaited(context.reveal());
  }

  Future<void> _openMirror(
    FeatureContext context,
    String deviceId,
    String deviceName,
  ) async {
    unawaited(viewerViewModel.start(deviceId));
    await _pushPage(context, deviceId, deviceName);
  }

  Future<void> _showTarget(FeatureContext context, MirrorTarget target) async {
    unawaited(viewerViewModel.startTarget(target));
    await _openPage(context, target);
  }

  /// A device started showing its screen here by itself: the viewer
  /// already plays it, so the page only has to come up.
  Future<void> _openIncoming(
    FeatureContext context,
    MirrorTarget target,
  ) async {
    unawaited(viewerViewModel.refreshWindow());
    unawaited(context.reveal());
    await _openPage(context, target);
  }

  /// Puts each device's question in front of the owner once, wherever
  /// they are in the app.
  void _askWhenRequested(FeatureContext context) {
    final requests = feature.routes?.requests ?? const <IncomingRequest>[];
    _asked.retainAll(requests);
    for (final request in requests) {
      if (_asked.add(request)) {
        unawaited(_ask(context, request));
      }
    }
  }

  Future<void> _ask(FeatureContext context, IncomingRequest request) async {
    final navigator = context.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final route = PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => ChangeNotifierProvider.value(
        value: viewerViewModel,
        child: AllowPage(request: request),
      ),
    );
    unawaited(context.reveal());
    unawaited(navigator.push(route));
    await request.answer;
    if (route.isActive) {
      navigator.removeRoute(route);
    }
  }

  Future<void> _openPage(FeatureContext context, MirrorTarget target) =>
      _pushPage(context, ViewSession.deviceIdOf(target), target.name);

  Future<void> _pushPage(
    FeatureContext context,
    String deviceId,
    String deviceName,
  ) async {
    await context.push<void>(
      ChangeNotifierProvider.value(
        value: viewerViewModel,
        child: MirrorPage(deviceId: deviceId, deviceName: deviceName),
      ),
    );
  }

  ConsentTexts _noticeTexts(String deviceName) {
    final l10n = platformMirroringL10n();
    return ConsentTexts(
      askTitle: l10n.askingTitle(deviceName),
      askBody: l10n.noticeAskBody,
      askChannelName: l10n.noticeAskChannel,
      sharingTitle: l10n.sharingTitle(deviceName),
      sharingBody: l10n.noticeSharingBody,
      stopLabel: l10n.stop,
      sharingChannelName: l10n.noticeSharingChannel,
    );
  }
}
