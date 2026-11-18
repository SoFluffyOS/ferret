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
/// LocalSend devices as extra targets, Quick Share from phones, notices,
/// and settings.
class DropFeatureUi extends FeatureUi {
  DropFeatureUi({FerretDrop? plugin, DropFeature? feature})
    : this._(plugin ?? FerretDrop(), feature);

  DropFeatureUi._(this._plugin, DropFeature? feature)
    : feature =
          feature ??
          DropFeature(
            store: (settings) =>
                PlatformReceiveStore(settings, plugin: _plugin),
            secrets: SupportSecretStore(),
          );

  @override
  final DropFeature feature;

  final FerretDrop _plugin;
  DropViewModel? _viewModel;
  DropNotices? _notices;
  StreamSubscription<SharedItems>? _shares;
  StreamSubscription<Transfer>? _offers;
  final Set<String> _revealed = {};

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

  /// Drop has no heartbeat of its own, so health is what really happened:
  /// the device said it offers Drop when it connected, and the last
  /// transfer with it either went through or didn't.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) =>
      healthOf(device);

  /// Transfers drive both the card and each device's health.
  @override
  Listenable get uiChanges => _dropViewModel;

  @override
  FeatureBusy busyState(FeatureContext feature) => _dropViewModel.busy;

  /// Drop's health with [device], from its session and the last transfer.
  FeatureHealth? healthOf(DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final l10n = _l10n();
    if (!session.supports(DropFeature.featureId)) {
      return FeatureHealth(
        .off,
        reason: l10n.failureUnsupported(device.device.name),
      );
    }

    final last = _lastFinished(device.device.id);
    if (last == null) {
      return FeatureHealth(
        .ok,
        reason: switch (_dropViewModel.receiveFolderLabel) {
          '' => l10n.healthOk,
          final folder => l10n.healthArrive(folder),
        },
      );
    }

    final stoppedByPeople = switch (last.failure) {
      TransferFailure.declined ||
      TransferFailure.cancelledByPeer ||
      TransferFailure.timedOut => true,
      _ => false,
    };
    if (last.status == .failed && !stoppedByPeople) {
      return FeatureHealth(.failing, reason: TransferTexts(l10n).failure(last));
    }

    return FeatureHealth(.ok, reason: l10n.healthSent);
  }

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final viewModel = _dropViewModel;
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
    _offers = feature.updates.listen(
      (transfer) => _revealQuickShareOffer(context, transfer),
    );
  }

  /// Someone is standing at a phone, waiting, and the PIN to compare is
  /// on the card: bring it to the front, once per offer.
  void _revealQuickShareOffer(FeatureContext context, Transfer transfer) {
    final isNewOffer =
        transfer.isQuickShare &&
        transfer.needsAnswer &&
        _revealed.add(transfer.id);
    if (!isNewOffer) {
      return;
    }

    unawaited(context.reveal());
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: _dropViewModel,
        child: DropHomeFrame(
          onSendFiles: () => unawaited(pickAndSend(feature)),
        ),
      );

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: _dropViewModel,
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
          _dropViewModel.pickAndSend(device.device.id),
        ),
      ),
    ];
  }

  @override
  Future<Stream<FilesSendProgress>?> onFilesDropped(
    FeatureContext feature,
    List<String> paths, {
    String? deviceId,
  }) async {
    final l10n = _l10n();
    final targets = _droppedTargets(deviceId);
    if (targets.isEmpty) {
      return Stream.value(FilesSendFailed(l10n.noticeNoDeviceBody));
    }

    final transferIds = <String>[];
    for (final target in targets) {
      final transfer = await _dropViewModel.sendFiles(target.deviceId, paths);
      if (transfer != null) {
        transferIds.add(transfer.id);
      }
    }
    if (transferIds.isEmpty) {
      return Stream.value(FilesSendFailed(l10n.noticeNothingBody));
    }

    return _progressOf(transferIds);
  }

  /// One summary of several transfers: failed as soon as one fails, sent
  /// once all are done, otherwise how far they got together.
  Stream<FilesSendProgress> _progressOf(List<String> transferIds) {
    final controller = StreamController<FilesSendProgress>();
    late final StreamSubscription<Transfer> subscription;

    void emit() {
      final progress = _summaryOf(transferIds);
      controller.add(progress);
      if (progress is FilesSending) {
        return;
      }

      unawaited(subscription.cancel());
      unawaited(controller.close());
    }

    subscription = feature.updates
        .where((transfer) => transferIds.contains(transfer.id))
        .listen((_) => emit());
    emit();
    return controller.stream;
  }

  FilesSendProgress _summaryOf(List<String> transferIds) {
    final transfers = [
      for (final id in transferIds) ?feature.registry[id],
    ];
    for (final transfer in transfers) {
      if (transfer.status == .failed || transfer.status == .cancelled) {
        return FilesSendFailed(TransferTexts(_l10n()).failure(transfer));
      }
    }

    final done = transfers.every((transfer) => transfer.status == .done);
    if (done) {
      return const FilesSent();
    }

    final total = transfers.fold(
      0.0,
      (sum, transfer) => sum + transfer.progress,
    );
    return FilesSending(total / transfers.length);
  }

  /// Dropped on one device, only that one; anywhere else, every connected
  /// paired device. LocalSend devices are never sent to without asking.
  List<DropTarget> _droppedTargets(String? deviceId) {
    final targets = _dropViewModel.targets;
    if (deviceId == null) {
      return targets;
    }

    return [
      for (final target in targets)
        if (target.deviceId == deviceId) target,
    ];
  }

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _shares?.cancel();
    await _offers?.cancel();
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

  /// The home card's Send button: asks which device, then which files.
  Future<void> pickAndSend(FeatureContext context) async {
    final target = await _chooseTarget(context, asked: true);
    if (target == null) {
      return;
    }

    final viewModel = _dropViewModel;
    final paths = await viewModel.pickFiles();
    if (paths.isEmpty) {
      return;
    }

    await _sendTo(context, target, paths: paths);
  }

  /// Sends [paths] or [text] to the one connected device, or asks which.
  Future<bool> _send(
    FeatureContext context, {
    List<String> paths = const [],
    String? text,
    bool temporary = false,
  }) async {
    final target = await _chooseTarget(context, asked: false);
    if (target == null) {
      return true;
    }

    await _sendTo(
      context,
      target,
      paths: paths,
      text: text,
      temporary: temporary,
    );
    return true;
  }

  Future<void> _sendTo(
    FeatureContext context,
    DropTarget target, {
    List<String> paths = const [],
    String? text,
    bool temporary = false,
  }) async {
    final viewModel = _dropViewModel;
    final l10n = _l10n();
    if (text != null) {
      final sent = viewModel.sendText(target.deviceId, text);
      if (sent == null) {
        await _notices?.explain(
          l10n.noticeGone(target.name),
          l10n.noticeGoneBody(target.name),
        );
      }

      return;
    }

    final transfer = await viewModel.sendFiles(
      target.deviceId,
      paths,
      temporary: temporary,
    );
    if (transfer != null) {
      return;
    }

    if (target.isLocalSend && viewModel.isGone(target)) {
      await _notices?.explain(
        l10n.noticeGone(target.name),
        l10n.noticeGoneBody(target.name),
      );
      return;
    }

    await _notices?.explain(l10n.noticeNothing, l10n.noticeNothingBody);
  }

  /// Picks where to send. Things dropped or shared go straight to the one
  /// connected paired device; a LocalSend device is never picked without
  /// asking. When someone [asked] to send, LocalSend devices are offered
  /// next to the paired ones.
  Future<DropTarget?> _chooseTarget(
    FeatureContext context, {
    required bool asked,
  }) async {
    final viewModel = _dropViewModel;
    final targets = viewModel.targets;
    final offerLocalSend = viewModel.localSendEnabled;
    if (targets.isEmpty && !offerLocalSend) {
      final l10n = _l10n();
      await _notices?.explain(l10n.noticeNoDevice, l10n.noticeNoDeviceBody);
      return null;
    }

    final skipPicker = !asked || !offerLocalSend;
    if (targets case [final only] when skipPicker) {
      return only;
    }

    final navigatorContext = context.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      return null;
    }

    return DevicePickerDialog.show(navigatorContext, viewModel);
  }

  Transfer? _lastFinished(String deviceId) {
    for (final transfer in feature.transfers) {
      if (transfer.deviceId == deviceId && !transfer.status.isActive) {
        return transfer;
      }
    }

    return null;
  }

  DropViewModel get _dropViewModel =>
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
