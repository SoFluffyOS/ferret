import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:photos/feature/feature.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/models/models.dart';
import 'package:photos/services/services.dart';
import 'package:photos/ui/frames/frames.dart';
import 'package:photos/ui/pages/pages.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The app side of photos. On a computer: a Photos section under each phone
/// that shares them, and Activity lines for what was saved. On a phone: a
/// switch per computer on its page (off by default), Photos in Settings,
/// and a notice when a computer asks.
class PhotosFeatureUi extends FeatureUi {
  PhotosFeatureUi({PhotosFeature? feature})
    : feature = feature ?? PhotosFeature();

  @override
  final PhotosFeature feature;

  static const sectionId = 'photos';
  static const _askNotice = '${PhotosFeature.featureId}.ask.';

  final Map<String, PhotoGalleryViewModel> _galleries = {};
  final Set<String> _sharers = {};
  final StreamController<void> _changes = .broadcast();
  late final FeatureChanges _uiChanges = FeatureChanges(_changes.stream);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  PhonePhotosViewModel? _phone;

  @override
  String get featureId => PhotosFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    PhotosLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.photosL10n.title;

  @override
  IconData get icon => LucideIcons.images;

  @override
  SettingsGroup get settingsGroup => .phone;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  Listenable? get uiChanges => _uiChanges;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions
      ..clear()
      ..add(feature.saves.changes.listen((_) => _changes.add(null)))
      ..add(feature.settings.changes.listen((_) => _changes.add(null)));

    if (!feature.isPhone) {
      final paths = await AppPaths.get();
      feature.useCache(ThumbnailCache(p.join(paths.cache, 'photos')));
      return;
    }

    final phone = PhonePhotosViewModel(feature);
    _phone = phone;
    await phone.refresh();
    _subscriptions
      ..add(
        feature.accessPrompts.listen(
          (deviceId) => unawaited(_showAsk(context, deviceId)),
        ),
      )
      ..add(
        context.notifier.responses
            .where((response) => response.noticeId.startsWith(_askNotice))
            .listen((response) => unawaited(_openAsk(context, response))),
      );
  }

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    final l10n = context.photosL10n;

    return [
      for (final save in this.feature.saves.all) _activityOf(l10n, save),
    ];
  }

  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (this.feature.isPhone) {
      return const [];
    }

    final deviceId = device.device.id;
    if (device.session case final session?
        when PhotosFeature.sharesPhotos(session)) {
      _sharers.add(deviceId);
    }

    if (!_sharers.contains(deviceId)) {
      return const [];
    }

    final gallery = _galleries.putIfAbsent(
      deviceId,
      () => PhotoGalleryViewModel(this.feature, deviceId),
    );

    return [
      FeatureSection(
        id: sectionId,
        title: title(context),
        icon: icon,
        order: 45,
        isSetUp: gallery.state != .notAllowed,
        builder: (_) => PhotosPage(
          key: ValueKey(deviceId),
          viewModel: gallery,
          deviceName: device.device.name,
          showsPreviews: feature.showsPreviewsFrom(deviceId),
          onOpen: (item) => unawaited(
            feature.push<void>(
              PhotoPreviewPage(viewModel: gallery, item: item),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final phone = _phone;
    if (phone == null || !_isComputer(device)) {
      return const [];
    }

    final l10n = context.photosL10n;
    final deviceId = device.device.id;
    final name = device.device.name;
    final detail = switch (phone.access) {
      .limited => l10n.permissionDetailLimited,
      .denied => l10n.permissionDetailDenied,
      _ => l10n.permissionDetail(name),
    };

    return [
      DevicePermission(
        label: l10n.permissionLabel(name),
        detail: detail,
        value: phone.sharesWith(deviceId),
        onChanged: (value) => unawaited(_setShares(phone, deviceId, value)),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final phone = _phone;
    if (phone == null) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: phone,
      child: const PhonePhotosFrame(),
    );
  }

  Future<void> _setShares(
    PhonePhotosViewModel phone,
    String deviceId,
    bool shared,
  ) async {
    await phone.setSharesWith(deviceId, shared: shared);
    _changes.add(null);
  }

  Future<void> _showAsk(FeatureContext context, String deviceId) {
    final l10n = _l10n;
    final name = feature.host.displayNameOf(deviceId);

    return context.notifier.show(
      LocalNotice(
        id: '$_askNotice$deviceId',
        channel: .incoming,
        title: l10n.noticeAskTitle(name),
        body: l10n.noticeAskBody,
      ),
    );
  }

  Future<void> _openAsk(FeatureContext context, NoticeResponse response) async {
    final phone = _phone;
    final deviceId = response.noticeId.substring(_askNotice.length);
    if (phone == null || deviceId.isEmpty) {
      return;
    }

    await context.reveal();
    await phone.refresh();
    await context.push<void>(
      PhonePhotosPage(
        viewModel: phone,
        deviceId: deviceId,
        deviceName: feature.host.displayNameOf(deviceId),
      ),
    );
  }

  ActivityItem _activityOf(PhotosLocalizations l10n, PhotoSave save) {
    final device = feature.host.displayNameOf(save.deviceId);
    final done = switch (save.isScreenshot) {
      true => l10n.activityScreenshot(device),
      false => l10n.activitySaved(save.count, device),
    };

    return switch (save.status) {
      .running => ActivityItem(
        id: save.id,
        icon: icon,
        title: l10n.activitySaving(save.count, device),
        pinned: true,
        progress: save.fraction,
        deviceId: save.deviceId,
      ),
      .done => ActivityItem(
        id: save.id,
        icon: icon,
        title: done,
        detail: l10n.activityInFolder,
        at: save.startedAt,
        files: save.paths,
        deviceId: save.deviceId,
        tone: .success,
        actions: [
          if (save.paths case [final path])
            ActivityAction(
              label: l10n.openSaved,
              onPressed: () => unawaited(feature.openSaved(path)),
            ),
          if (save.paths case [final path, ...])
            ActivityAction(
              label: switch (defaultTargetPlatform) {
                .macOS => l10n.revealSavedFinder,
                _ => l10n.revealSaved,
              },
              onPressed: () => unawaited(feature.revealSaved(path)),
            ),
        ],
        private: PrivateContent(save.deviceId, cover: done),
        onDismiss: () => feature.saves.remove(save.id),
      ),
      .failed => ActivityItem(
        id: save.id,
        icon: icon,
        title: l10n.activityFailed(device),
        detail: switch (save.problem) {
          .offline => l10n.failOffline(device),
          .notAllowed => l10n.failNotAllowed(device),
          .noPermission => l10n.failNoPermission(device),
          .missing => l10n.failMissing(device),
          .failed || null => l10n.failOther,
        },
        at: save.startedAt,
        deviceId: save.deviceId,
        tone: .danger,
        onDismiss: () => feature.saves.remove(save.id),
      ),
    };
  }

  static bool _isComputer(DeviceStatus device) {
    if (device.session?.remoteFeature(PhotosFeature.featureId)
        case final support?) {
      return support.flags.contains(PhotosFeature.browseFlag);
    }

    return switch (device.device.formFactor) {
      .FORM_FACTOR_DESKTOP || .FORM_FACTOR_LAPTOP => true,
      _ => false,
    };
  }

  static PhotosLocalizations get _l10n => lookupPhotosLocalizations(
    AppLocale.pick(PhotosLocalizations.supportedLocales),
  );
}
