import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phone_camera/feature/feature.dart';
import 'package:phone_camera/l10n/l10n.dart';
import 'package:phone_camera/models/models.dart';
import 'package:phone_camera/ui/camera_activity.dart';
import 'package:phone_camera/ui/frames/frames.dart';
import 'package:phone_camera/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The app side of the camera. On a computer: Take a photo (and Scan a
/// document for an iPhone) on each phone's page, which the window's Device
/// menu, ••• and ⌃⌘P run too, and an Activity line for each request. On a
/// phone: a card and a notice for each request, with Take photo and Not
/// now.
class CameraFeatureUi extends FeatureUi {
  CameraFeatureUi({CameraFeature? feature})
    : feature = feature ?? CameraFeature();

  @override
  final CameraFeature feature;

  /// The id of Take a photo, which the window's ⌃⌘P runs.
  static const photoActionId = 'camera.photo';
  static const scanActionId = 'camera.scan';
  static const _askNotice = '${CameraFeature.featureId}.ask.';

  late final CaptureAsksViewModel asks = CaptureAsksViewModel(feature);
  final StreamController<void> _changes = .broadcast();
  late final FeatureChanges _uiChanges = FeatureChanges(_changes.stream);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Set<String> _noticed = {};

  @override
  String get featureId => CameraFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    CameraLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.cameraL10n.title;

  @override
  IconData get icon => LucideIcons.camera;

  @override
  Listenable? get uiChanges => _uiChanges;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions
      ..clear()
      ..add(feature.jobs.changes.listen((_) => _changes.add(null)))
      ..add(
        feature.askChanges.listen((_) {
          _changes.add(null);
          unawaited(_syncNotices(context));
        }),
      )
      ..add(
        context.notifier.responses
            .where((response) => response.noticeId.startsWith(_askNotice))
            .listen((_) => unawaited(context.reveal())),
      );
  }

  @override
  bool hasHomeCard(FeatureContext feature) => this.feature.asks.isNotEmpty;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (!this.feature.isPhone) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: asks,
      child: const CaptureAsksFrame(),
    );
  }

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      cameraActivity(context.cameraL10n, this.feature);

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    if (this.feature.isPhone || session == null) {
      return const [];
    }

    final l10n = context.cameraL10n;
    final deviceId = device.device.id;

    return [
      if (CameraFeature.takesPhotos(session))
        FeatureAction(
          id: photoActionId,
          label: l10n.takePhoto,
          icon: LucideIcons.camera,
          onPressed: () => unawaited(this.feature.request(deviceId)),
        ),
      if (CameraFeature.scansDocuments(session))
        FeatureAction(
          id: scanActionId,
          label: l10n.scanDocument,
          icon: LucideIcons.scanLine,
          onPressed: () => unawaited(
            this.feature.request(deviceId, kind: .document),
          ),
        ),
    ];
  }

  /// One notice per waiting request, taken away once it is answered, and
  /// Ferret brought to the front where it can be.
  Future<void> _syncNotices(FeatureContext context) async {
    final waiting = {
      for (final ask in feature.asks)
        if (!ask.isCapturing) ask.requestId: ask,
    };
    for (final requestId in [..._noticed]) {
      if (waiting.containsKey(requestId)) {
        continue;
      }

      _noticed.remove(requestId);
      await context.notifier.cancel('$_askNotice$requestId');
    }

    for (final MapEntry(key: requestId, value: ask) in waiting.entries) {
      if (!_noticed.add(requestId)) {
        continue;
      }

      await _showNotice(context, ask);
      await context.reveal();
    }
  }

  Future<void> _showNotice(FeatureContext context, CaptureAsk ask) {
    final l10n = _l10n;
    final name = feature.host.displayNameOf(ask.deviceId);

    return context.notifier.show(
      LocalNotice(
        id: '$_askNotice${ask.requestId}',
        channel: .incoming,
        title: switch (ask.kind) {
          .photo => l10n.askPhotoTitle(name),
          .document => l10n.askDocumentTitle(name),
        },
        body: l10n.noticeBody(ThisComputer.handheld),
      ),
    );
  }

  static CameraLocalizations get _l10n => lookupCameraLocalizations(
    AppLocale.pick(CameraLocalizations.supportedLocales),
  );
}
