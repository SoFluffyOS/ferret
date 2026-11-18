import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/l10n/l10n.dart';
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
  MirroringFeatureUi({MirroringFeature? feature, MirrorWindow? window})
    : feature = feature ?? MirroringFeature(),
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
        onOpen: (session) => unawaited(
          _openMirror(feature, session.deviceId, session.deviceName),
        ),
      ),
    );
  }

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    final viewer = this.feature.viewer;
    if (session == null ||
        viewer == null ||
        !this.feature.canViewDevice(session)) {
      return null;
    }

    final deviceId = device.device.id;
    final name = device.device.name;
    final l10n = platformMirroringL10n();
    final current = viewer.current;
    if (current != null &&
        current.deviceId == deviceId &&
        current.isMirroring) {
      return FeatureHealth(.ok, reason: l10n.healthViewing);
    }

    return switch (viewer.lastEndFor(deviceId)) {
      .turnedOff => FeatureHealth(.off, reason: l10n.healthTurnedOff(name)),
      .unsupported => FeatureHealth(.off, reason: l10n.healthUnsupported(name)),
      .cannotAsk => FeatureHealth(
        .needsAttention,
        reason: l10n.healthCannotAsk(name),
      ),
      .failed => FeatureHealth(.failing, reason: l10n.endFailedBody(name)),
      .decoderFailed => FeatureHealth(
        .failing,
        reason: l10n.endDecoderFailedBody,
      ),
      _ => null,
    };
  }

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    if (session == null || !this.feature.canViewDevice(session)) {
      return const [];
    }

    return [
      FeatureAction(
        label: context.mirroringL10n.showScreen,
        icon: LucideIcons.screenShare,
        onPressed: () => unawaited(
          _openMirror(feature, device.device.id, device.device.name),
        ),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final sections = [
      if (shareViewModel.isAvailable)
        ChangeNotifierProvider.value(
          value: shareViewModel,
          child: const ShareSettingsFrame(),
        ),
      if (viewerViewModel.isAvailable && _hasViewerSettings(feature))
        ChangeNotifierProvider.value(
          value: viewerViewModel,
          child: const ViewerSettingsFrame(),
        ),
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

  /// A computer's section only helps once an Android phone is paired, or
  /// to keep showing what it mirrored before.
  bool _hasViewerSettings(FeatureContext featureContext) =>
      viewerViewModel.history.isNotEmpty ||
      featureContext.engine.devices.any(
        (status) => status.device.platform == .PLATFORM_ANDROID,
      );

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _revealOnAsk?.cancel();
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
