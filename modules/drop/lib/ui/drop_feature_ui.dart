import 'dart:async';

import 'package:core/core.dart';
import 'package:drop/feature/drop_feature.dart';
import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/platform/platform.dart';
import 'package:drop/services/services.dart';
import 'package:drop/ui/dialogs/dialogs.dart';
import 'package:drop/ui/drop_activity.dart';
import 'package:drop/ui/drop_health.dart';
import 'package:drop/ui/frames/frames.dart';
import 'package:drop/ui/pages/pages.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Drop: transfers in Activity, "Send files" on each device,
/// files dropped on the window or menubar icon, shares from other apps and
/// from the file manager, LocalSend devices as extra targets, Quick Share
/// from phones, notices, and settings.
class DropFeatureUi extends FeatureUi {
  /// The id of the section a device's files show in.
  static const sectionId = 'files';

  /// [filesToSend] are the files this run was started with (`ferret send`),
  /// sent once the app is up. [handoff] takes the files of later runs. A
  /// share waits up to [connectGrace] for a device to connect, since the
  /// share may be what started or woke Ferret.
  DropFeatureUi({
    FerretDrop? plugin,
    DropFeature? feature,
    List<String> filesToSend = const [],
    SendHandoff? handoff,
    Duration connectGrace = const Duration(seconds: 10),
    Future<String> Function()? describeFolder,
  }) : this._(
         plugin ?? FerretDrop(),
         feature,
         filesToSend,
         handoff,
         connectGrace,
         describeFolder,
       );

  DropFeatureUi._(
    this._plugin,
    DropFeature? feature,
    this._filesToSend,
    this._handoff,
    this._connectGrace,
    this._describeFolder,
  ) : feature =
          feature ??
          DropFeature(
            store: (settings) =>
                PlatformReceiveStore(settings, plugin: _plugin),
            secrets: SupportSecretStore(),
          );

  @override
  final DropFeature feature;

  final FerretDrop _plugin;
  final List<String> _filesToSend;
  final Duration _connectGrace;

  /// Where received files go, as the receive folder says it; this
  /// platform's answer when null.
  final Future<String> Function()? _describeFolder;
  final Stopwatch _sinceAwake = Stopwatch();
  final SendHandoff? _handoff;
  DropViewModel? _viewModel;
  DropNotices? _notices;
  StreamSubscription<SharedItems>? _shares;
  StreamSubscription<List<String>>? _handedOver;
  String? _publishedTargets;
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

    final last = _lastFinished(device.device.id);
    return dropHealthOf(
      _l10n(),
      name: device.device.name,
      supported: session.supports(DropFeature.featureId),
      last: last,
      folder: _dropViewModel.receiveFolderText(_l10n()),
      onRetry: switch (last) {
        final last? when feature.canRetry(last) => () => unawaited(
          _dropViewModel.retry(last),
        ),
        _ => null,
      },
    );
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
      onMakeRoom: viewModel.makeRoom,
      folderLabel: () => viewModel.receiveFolderText(_l10n()),
    )..start();
    _notices = notices;
    _shares = _plugin.shares.listen(
      (items) => unawaited(_onShared(context, items)),
    );
    _offers = feature.updates.listen(
      (transfer) => _revealQuickShareOffer(context, transfer),
    );
    _sinceAwake.start();
    viewModel.addListener(_publishShareTargets);
    _publishShareTargets();
    await _takeSendCommands(context);
  }

  /// `ferret send <file>…` from a file manager: this run's files now, and
  /// those of later runs as they hand them over.
  Future<void> _takeSendCommands(FeatureContext context) async {
    if (_handoff case final handoff?) {
      _handedOver = handoff.requests.listen(
        (paths) => unawaited(_takeHandedOver(context, paths)),
      );
      await handoff.listen();
    }

    if (_filesToSend.isNotEmpty) {
      unawaited(_shareTo(context, paths: _filesToSend));
    }
  }

  Future<void> _takeHandedOver(
    FeatureContext context,
    List<String> paths,
  ) async {
    if (paths.isEmpty) {
      await context.reveal();
      return;
    }

    await _shareTo(context, paths: paths);
  }

  /// Keeps the system's share sheet in step with the connected devices,
  /// where it lists them (Finder's Share menu, Android's Direct Share row).
  void _publishShareTargets() {
    final targets = [
      for (final target in _dropViewModel.targets)
        ShareTarget(
          deviceId: target.deviceId,
          name: target.name,
          kind: switch (target.formFactor) {
            .FORM_FACTOR_PHONE => 'phone',
            .FORM_FACTOR_TABLET => 'tablet',
            .FORM_FACTOR_DESKTOP || .FORM_FACTOR_SERVER => 'desktop',
            _ => 'laptop',
          },
        ),
    ];
    final signature = [
      for (final target in targets)
        '${target.deviceId}\n${target.name}\n${target.kind}',
    ].join('\n\n');
    if (signature == _publishedTargets) {
      return;
    }

    _publishedTargets = signature;
    unawaited(_plugin.setShareTargets(targets));
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

  /// Only while a send waits for a PIN, or phones without Ferret are being
  /// let in. Offers to answer sit under Needs you and transfers in
  /// Activity, both from [activity].
  @override
  bool hasHomeCard(FeatureContext feature) =>
      _dropViewModel.needingPin.isNotEmpty || _dropViewModel.isOpenToOthers;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: _dropViewModel,
        child: DropHomeFrame(
          needsYouOnly: true,
          onSendFiles: () => unawaited(pickAndSend(feature)),
        ),
      );

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      dropActivity(
        context.dropL10n,
        _dropViewModel,
        onOfferDetails: (transfer) =>
            unawaited(_showOfferDetails(context, transfer)),
      );

  /// Who is sending, what and how much, and for a device that isn't paired
  /// its fingerprint or the PIN to compare, then Accept or Decline.
  Future<void> _showOfferDetails(
    BuildContext context,
    Transfer transfer,
  ) async {
    final l10n = context.dropL10n;
    final texts = TransferTexts(l10n);
    final answer = await FerretConfirmDialog.show(
      context,
      title: l10n.activityOffer(transfer.deviceName),
      message: [
        texts.title(transfer),
        ...texts.offerDetails(transfer),
      ].join('\n'),
      negativeText: l10n.actionDecline,
      positiveText: l10n.actionAccept,
    );
    final stillWaiting = feature.registry[transfer.id]?.needsAnswer ?? false;
    if (!stillWaiting) {
      return;
    }

    switch (answer) {
      case .positive:
        _dropViewModel.accept(transfer);
      case .negative:
        _dropViewModel.decline(transfer);
      case .dismiss:
        return;
    }
  }

  /// Letting a guest's phone without Ferret send one file here is one tap
  /// away, without a card that stays. Longer windows sit in Drop's card.
  @override
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) {
    if (!_dropViewModel.canOpenToOthers) {
      return null;
    }

    final l10n = context.dropL10n;
    return FeatureOffer(
      title: l10n.guestTitle,
      description: switch (_dropViewModel.quickShareSupported) {
        true => l10n.guestBody,
        false => l10n.guestBodyLocalSend,
      },
      actionLabel: l10n.guestAction,
      onAction: () => unawaited(_dropViewModel.receiveFromGuest()),
    );
  }

  @override
  SettingsGroup get settingsGroup => .files;

  @override
  Widget buildSettings(BuildContext context, FeatureContext feature) =>
      _settingsPart(const DropSettingsFrame());

  /// Where files go sits under Files; LocalSend and Quick Share, each
  /// where it can work, sit with the other apps Ferret works with. Those
  /// count as on only while they may send here.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.dropL10n;
    final viewModel = _dropViewModel;
    final localSend = viewModel.localSendEnabled;
    final receiving = viewModel.receiveState;

    return [
      FeatureSettings(
        group: settingsGroup,
        title: l10n.title,
        child: buildSettings(context, feature),
        summary: filesSummaryOf(l10n, viewModel.receiveFolderText(l10n)),
      ),
      FeatureSettings(
        group: .otherApps,
        title: l10n.receiveTitle,
        child: _settingsPart(const LocalSendSettingsFrame()),
        summary: localSendSummaryOf(
          l10n,
          isEnabled: localSend,
          receiveAlways: viewModel.receiveAlways,
          state: receiving,
        ),
        isOn: localSend,
        needsAttention:
            localSend && viewModel.receiveAlways && receiving.problem != null,
      ),
      if (viewModel.quickShareSupported)
        FeatureSettings(
          group: .otherApps,
          title: l10n.quickShareTitle,
          child: _settingsPart(const QuickShareSettingsFrame()),
          summary: quickShareSummaryOf(
            l10n,
            isEnabled: viewModel.quickShareEnabled,
            state: viewModel.quickShareState,
          ),
          isOn: viewModel.quickShareEnabled,
        ),
    ];
  }

  Widget _settingsPart(Widget frame) =>
      ChangeNotifierProvider.value(value: _dropViewModel, child: frame);

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
        id: 'drop.send_files',
        label: context.dropL10n.sendFiles,
        icon: LucideIcons.upload,
        homeOrder: 10,
        onPressed: () => unawaited(
          _dropViewModel.pickAndSend(device.device.id),
        ),
      ),
      if (_dropViewModel.canPickFolder)
        FeatureAction(
          id: 'drop.send_folder',
          label: context.dropL10n.sendFolder,
          icon: LucideIcons.folderUp,
          onPressed: () => unawaited(
            _dropViewModel.pickFolderAndSend(device.device.id),
          ),
        ),
    ];
  }

  /// The devices that took files since Ferret started, so their Files
  /// section stays while one of them is offline.
  final Set<String> _tookFiles = {};

  /// Files with one device: for a device that takes them, and for one
  /// that still has transfers listed here.
  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final deviceId = device.device.id;
    final takesFiles = device.session?.supports(DropFeature.featureId) ?? false;
    final hasTransfers = _dropViewModel.transfers.any(
      (transfer) => transfer.deviceId == deviceId,
    );
    if (takesFiles) {
      _tookFiles.add(deviceId);
    }

    if (!_tookFiles.contains(deviceId) && !hasTransfers) {
      return const [];
    }

    return [
      FeatureSection(
        id: sectionId,
        title: title(context),
        icon: LucideIcons.folder,
        order: 40,
        builder: (_) => FilesPage(
          viewModel: _dropViewModel,
          deviceId: deviceId,
          deviceName: device.device.name,
          isConnected: takesFiles,
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
    await _handedOver?.cancel();
    await _handoff?.dispose();
    _viewModel?.removeListener(_publishShareTargets);
    await _notices?.dispose();
    _viewModel?.dispose();
  }

  Future<void> _onShared(FeatureContext context, SharedItems items) async {
    // On iOS a share is picked up as Ferret comes back to the front, when
    // iOS had cut its connections in the background.
    _sinceAwake.reset();
    final pickedInSheet =
        items.deviceId != null || (items.everyDevice ?? false);
    if (items.paths.isNotEmpty) {
      await _shareTo(
        context,
        paths: items.paths,
        deviceId: items.deviceId,
        pickedInSheet: pickedInSheet,
        temporary: !(items.keepFiles ?? false),
      );
      return;
    }

    if (items.text case final text? when text.isNotEmpty) {
      await _shareTo(
        context,
        text: text,
        deviceId: items.deviceId,
        pickedInSheet: pickedInSheet,
      );
    }
  }

  /// Sends what a share sheet or a file manager handed over. When the
  /// device was [pickedInSheet] it goes there ([deviceId]) or to every
  /// connected device; otherwise to the one connected device, or Ferret
  /// comes forward and asks which.
  Future<void> _shareTo(
    FeatureContext context, {
    List<String> paths = const [],
    String? text,
    String? deviceId,
    bool pickedInSheet = false,
    bool temporary = false,
  }) async {
    await _untilConnected(deviceId);
    if (!pickedInSheet) {
      await _send(context, paths: paths, text: text, temporary: temporary);
      return;
    }

    final targets = _droppedTargets(deviceId);
    if (targets.isEmpty) {
      final l10n = _l10n();
      await _notices?.explain(l10n.noticeNoDevice, l10n.noticeNoDeviceBody);
      return;
    }

    // Copies sent to several devices can't be deleted when the first one
    // finishes; the platform clears those out later.
    final deleteAfter = temporary && targets.length == 1;
    for (final target in targets) {
      await _sendTo(
        context,
        target,
        paths: paths,
        text: text,
        temporary: deleteAfter,
      );
    }
  }

  /// Right after starting, or after a share sheet brought Ferret back, devices
  /// are still connecting: waits for [deviceId] (or any device) until
  /// [_connectGrace] after that moment.
  Future<void> _untilConnected(String? deviceId) async {
    final viewModel = _dropViewModel;
    bool isConnected() => viewModel.targets.any(
      (target) => deviceId == null || target.deviceId == deviceId,
    );
    final left = _connectGrace - _sinceAwake.elapsed;
    if (isConnected() || left <= Duration.zero) {
      return;
    }

    final connected = Completer<void>();
    void check() {
      if (isConnected() && !connected.isCompleted) {
        connected.complete();
      }
    }

    viewModel.addListener(check);
    await connected.future.timeout(left, onTimeout: () {});
    viewModel.removeListener(check);
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

    await _sendTo(
      context,
      target,
      paths: paths,
      temporary: viewModel.picksCopies,
    );
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

    if (!asked) {
      await context.reveal();
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

  DropViewModel get _dropViewModel => _viewModel ??= DropViewModel(
    feature: feature,
    plugin: _plugin,
    describeFolder: _describeFolder,
  );

  DropLocalizations _l10n() => lookupDropLocalizations(
    AppLocale.pick(DropLocalizations.supportedLocales),
  );
}
