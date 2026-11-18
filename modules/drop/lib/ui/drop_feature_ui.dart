import 'dart:async';
import 'dart:ui';

import 'package:drop/feature/drop_feature.dart';
import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/platform/platform.dart';
import 'package:drop/services/services.dart';
import 'package:drop/ui/dialogs/dialogs.dart';
import 'package:drop/ui/frames/frames.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Drop: the home card, "Send files…" on each device,
/// files dropped on the window or menubar icon, shares from other apps,
/// notices, and settings.
class DropFeatureUi extends FeatureUi {
  DropFeatureUi({FerretDrop? plugin, DropFeature? feature})
    : this._(plugin ?? FerretDrop(), feature);

  DropFeatureUi._(this._plugin, DropFeature? feature)
    : feature =
          feature ??
          DropFeature(
            store: (settings) =>
                PlatformReceiveStore(settings, plugin: _plugin),
          );

  @override
  final DropFeature feature;

  final FerretDrop _plugin;
  DropViewModel? _viewModel;
  DropNotices? _notices;
  StreamSubscription<SharedItems>? _shares;

  @override
  String get featureId => DropFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    DropLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories => DropNotices.categories(_l10n());

  @override
  String title(BuildContext context) => context.dropL10n.title;

  @override
  IconData get icon => LucideIcons.send;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final viewModel = _viewModelFor(context);
    final notices = DropNotices(
      feature: feature,
      notifier: context.notifier,
      l10n: _l10n(),
      onOpen: viewModel.open,
      onReveal: viewModel.reveal,
      onCopy: viewModel.copyText,
    )..start();
    _notices = notices;
    _shares = _plugin.shares.listen(
      (items) => unawaited(_onShared(context, items)),
    );
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: _viewModelFor(feature),
        child: DropHomeFrame(
          onSendFiles: () => unawaited(_pickAndSend(feature)),
        ),
      );

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: _viewModelFor(feature),
        child: const DropSettingsFrame(),
      );

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    if (session == null || !session.supports(DropFeature.featureId)) {
      return const [];
    }

    return [
      FeatureAction(
        label: context.dropL10n.sendFiles,
        icon: LucideIcons.upload,
        onPressed: () => unawaited(
          _viewModelFor(feature).pickAndSend(device.device.id),
        ),
      ),
    ];
  }

  @override
  Future<bool> onFilesDropped(FeatureContext feature, List<String> paths) =>
      _send(feature, paths: paths);

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _shares?.cancel();
    await _notices?.dispose();
    _viewModel?.dispose();
  }

  Future<void> _onShared(FeatureContext context, SharedItems items) async {
    if (items.paths.isNotEmpty) {
      await _send(context, paths: items.paths, temporary: true);
      return;
    }

    if (items.text case final text? when text.isNotEmpty) {
      await _send(context, text: text);
    }
  }

  Future<void> _pickAndSend(FeatureContext context) async {
    final target = await _chooseTarget(context);
    if (target == null) {
      return;
    }

    await _viewModelFor(context).pickAndSend(target.deviceId);
  }

  /// Sends [paths] or [text] to the one connected device, or asks which.
  Future<bool> _send(
    FeatureContext context, {
    List<String> paths = const [],
    String? text,
    bool temporary = false,
  }) async {
    final target = await _chooseTarget(context);
    if (target == null) {
      return true;
    }

    final viewModel = _viewModelFor(context);
    if (text != null) {
      viewModel.sendText(target.deviceId, text);
      return true;
    }

    final transfer = await viewModel.sendFiles(
      target.deviceId,
      paths,
      temporary: temporary,
    );
    if (transfer == null) {
      final l10n = _l10n();
      await _notices?.explain(l10n.noticeNothing, l10n.noticeNothingBody);
    }

    return true;
  }

  Future<DropTarget?> _chooseTarget(FeatureContext context) async {
    final targets = _viewModelFor(context).targets;
    if (targets.isEmpty) {
      final l10n = _l10n();
      await _notices?.explain(l10n.noticeNoDevice, l10n.noticeNoDeviceBody);
      return null;
    }

    if (targets case [final only]) {
      return only;
    }

    final navigatorContext = context.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      return null;
    }

    return DevicePickerDialog.show(navigatorContext, targets);
  }

  DropViewModel _viewModelFor(FeatureContext context) =>
      _viewModel ??= DropViewModel(feature: feature, plugin: _plugin);

  DropLocalizations _l10n() {
    final wanted = PlatformDispatcher.instance.locale;
    for (final locale in DropLocalizations.supportedLocales) {
      if (locale.languageCode == wanted.languageCode) {
        return lookupDropLocalizations(locale);
      }
    }

    return lookupDropLocalizations(DropLocalizations.supportedLocales.first);
  }
}
