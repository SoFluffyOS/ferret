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
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The app side of Screen. On a computer: "Show screen" on every phone
/// and tablet, the mirror stage that tells the whole story from the first
/// question to the ending, a pinned Activity line while a screen is
/// shown, and a line under Nearby for each phone on a cable that isn't
/// paired. On a
/// phone: the "Sharing screen with MacBook · Stop" card (next to Android's
/// own ongoing notice), the audit line, and Settings with the history.
/// Between two Macs: "Use MacBook Air as a display" on the one that lends
/// its desktop, the question and the full-screen display on the other.
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
    this.feature.cameraTexts = _cameraNoticeTexts;
  }

  @override
  final MirroringFeature feature;

  final MirrorWindow? _window;

  /// The id of a device's Screen section.
  static const sectionId = 'screen';

  static const _requestCategory = 'mirroring.request';
  static const _displayRequestCategory = 'mirroring.display_request';
  static const _requestNotice = 'mirroring.request';
  static const _showAction = 'mirroring.show';
  static const _denyAction = 'mirroring.deny';
  static const _controlAskCategory = 'mirroring.control_ask';
  static const _controlAskNotice = 'mirroring.control_ask';
  static const _controlledCategory = 'mirroring.controlled';
  static const _controlledNotice = 'mirroring.controlled';
  static const _alwaysAction = 'mirroring.control_always';
  static const _onceAction = 'mirroring.control_once';
  static const _noAction = 'mirroring.control_no';
  static const _stopControlAction = 'mirroring.control_stop';
  static const _cameraAskCategory = 'mirroring.camera_ask';
  static const _cameraAskNotice = 'mirroring.camera_ask';
  static const _cameraOnceAction = 'mirroring.camera_once';
  static const _cameraAlwaysAction = 'mirroring.camera_always';
  static const _cameraNoAction = 'mirroring.camera_no';
  static const _displayingCategory = 'mirroring.displaying';
  static const _displayingNotice = 'mirroring.displaying';
  static const _stopDisplayAction = 'mirroring.display_stop';

  /// Where "Show screen" sits among a device's first actions: right
  /// after Send files.
  static const _homeOrder = 15;

  late final ViewerViewModel viewerViewModel = ViewerViewModel(
    feature,
    window: _window,
  );
  late final StageWindowViewModel stageWindow = StageWindowViewModel(
    viewerViewModel,
  );
  late final ShareViewModel shareViewModel = ShareViewModel(feature);
  late final FeatureChanges _changes = FeatureChanges(feature.changes);
  StreamSubscription<void>? _revealOnAsk;
  StreamSubscription<MirrorFeed>? _openOnIncoming;
  StreamSubscription<void>? _askOnRequest;
  StreamSubscription<NoticeResponse>? _noticeResponses;
  StreamSubscription<void>? _controlNotices;
  StreamSubscription<NoticeResponse>? _controlResponses;
  StreamSubscription<void>? _cameraNotices;
  StreamSubscription<NoticeResponse>? _cameraResponses;
  StreamSubscription<void>? _displayNotices;
  StreamSubscription<NoticeResponse>? _displayResponses;

  /// The display "This phone is MacBook's display" was last shown for.
  MirrorTarget? _displayNoticeShown;
  ShareRequest? _cameraAskShown;
  final Set<IncomingRequest> _asked = {};
  ControlRequest? _controlAskShown;
  ControlRequest? _controlledShown;

  StreamSubscription<void>? _openOnDisplay;

  /// The display the window was last opened for, so it opens once.
  MirrorTarget? _displayShown;

  /// The page another computer's display fills, where there is no
  /// window for it: a phone's.
  Route<void>? _displayPage;

  /// The mirror page that is open, so a second one takes its place
  /// instead of piling up on it.
  Route<void>? _page;
  String? _pageDeviceId;

  /// When the request the app was last brought to the front for was made.
  DateTime? _revealedFor;

  @override
  String get featureId => MirroringFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MirroringLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories {
    final l10n = platformMirroringL10n();
    return [
      NoticeCategory(
        id: _requestCategory,
        actions: [
          NoticeAction(id: _showAction, label: l10n.allow, opensApp: true),
          NoticeAction(id: _denyAction, label: l10n.dontAllow),
        ],
      ),
      NoticeCategory(
        id: _displayRequestCategory,
        actions: [
          NoticeAction(
            id: _showAction,
            label: l10n.displayAllow,
            opensApp: true,
          ),
          NoticeAction(id: _denyAction, label: l10n.dontAllow),
        ],
      ),
      NoticeCategory(
        id: _controlAskCategory,
        actions: [
          NoticeAction(
            id: _onceAction,
            label: l10n.controlOnce,
            opensApp: true,
          ),
          NoticeAction(
            id: _alwaysAction,
            label: l10n.controlAlways,
            opensApp: true,
          ),
          NoticeAction(id: _noAction, label: l10n.controlNo),
        ],
      ),
      NoticeCategory(
        id: _controlledCategory,
        actions: [NoticeAction(id: _stopControlAction, label: l10n.stop)],
      ),
      NoticeCategory(
        id: _displayingCategory,
        actions: [NoticeAction(id: _stopDisplayAction, label: l10n.stop)],
      ),
      NoticeCategory(
        id: _cameraAskCategory,
        actions: [
          NoticeAction(
            id: _cameraOnceAction,
            label: l10n.controlOnce,
            opensApp: true,
          ),
          NoticeAction(
            id: _cameraAlwaysAction,
            label: l10n.controlAlways,
            opensApp: true,
          ),
          NoticeAction(id: _cameraNoAction, label: l10n.controlNo),
        ],
      ),
    ];
  }

  @override
  String title(BuildContext context) => context.mirroringL10n.title;

  @override
  IconData get icon => LucideIcons.screenShare;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    stageWindow.attach(context.windows);
    _openOnIncoming = feature.routes?.incoming.listen(
      (feed) => unawaited(_openIncoming(context, feed.target)),
    );
    _askOnRequest = feature.changes.listen((_) => _askWhenRequested(context));
    _openOnDisplay = feature.changes.listen(
      (_) => _openDisplayWhenAllowed(context),
    );
    _noticeResponses = context.notifier.responses
        .where((response) => response.noticeId == _requestNotice)
        .listen(_onNoticeResponse);
    if (DisplayHere.isTouch) {
      _displayNotices = feature.changes.listen(
        (_) => _syncDisplayNotice(context),
      );
      _displayResponses = context.notifier.responses
          .where((response) => response.noticeId == _displayingNotice)
          .listen((response) => _onDisplayResponse(context, response));
    }

    if (feature.source == null) {
      return;
    }

    _revealOnAsk = feature.changes.listen((_) => _revealWhenAsked(context));
    _controlNotices = feature.changes.listen(
      (_) => _syncControlNotices(context),
    );
    _controlResponses = context.notifier.responses
        .where(
          (response) =>
              response.noticeId == _controlAskNotice ||
              response.noticeId == _controlledNotice,
        )
        .listen(_onControlResponse);
    _cameraNotices = feature.changes.listen((_) => _syncCameraNotice(context));
    _cameraResponses = context.notifier.responses
        .where((response) => response.noticeId == _cameraAskNotice)
        .listen(_onCameraResponse);
  }

  @override
  Listenable get uiChanges => _changes;

  /// While a device sees this screen, or shows this Mac's extra display,
  /// the menubar icon says so.
  @override
  FeatureBusy? busyState(FeatureContext feature) {
    if (shareViewModel.active case final active?) {
      return FeatureBusy(screenSeenBy: active.deviceName);
    }

    final lent = this.feature.display?.current;
    if (lent != null && lent.phase == .extending) {
      return FeatureBusy(screenSeenBy: lent.deviceName);
    }

    return null;
  }

  /// A phone's card while its screen is asked for or shared, or just
  /// was. A computer has none: what it can show is on its devices.
  @override
  bool hasHomeCard(FeatureContext feature) => shareViewModel.hasCard;

  /// Once, or Stop while a computer sees or controls this phone.
  @override
  bool homeCardHoldsPrimary(FeatureContext feature) =>
      shareViewModel.isAvailable &&
      (shareViewModel.controlPending != null ||
          shareViewModel.active != null ||
          shareViewModel.cameraPending != null ||
          shareViewModel.cameraActive != null);

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (!shareViewModel.isAvailable || !shareViewModel.hasCard) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: shareViewModel,
      child: const ShareCardFrame(),
    );
  }

  /// The phones on a cable that aren't paired: each one is near, and its
  /// screen can be shown without pairing.
  @override
  List<FeatureNearbyRow> nearbyRows(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.mirroringL10n;

    return [
      for (final target in viewerViewModel.targets)
        FeatureNearbyRow(
          id: '$featureId.${target.id}',
          title: target.name,
          detail: l10n.targetLine(target),
          icon: LucideIcons.smartphone,
          actionLabel: l10n.showScreen,
          onAction: () => unawaited(_showTarget(feature, target)),
        ),
    ];
  }

  /// A device that asks to show its screen needs the person; the screen
  /// being shown stays pinned with Stop; the last one shown leaves a line.
  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    final l10n = context.mirroringL10n;
    final current = viewerViewModel.current;
    final record = viewerViewModel.lastRecord;
    final asksOnStage = viewerViewModel.airplayGuideFor != null;

    return [
      if (!asksOnStage)
        for (final request in viewerViewModel.requests)
          ActivityItem(
            id: 'mirroring.request.${request.askedAt.millisecondsSinceEpoch}',
            icon: switch (request.display) {
              true => LucideIcons.monitor,
              false => LucideIcons.screenShare,
            },
            title: switch (request.display) {
              true => l10n.displayAllowTitle(
                request.deviceName,
                DisplayHere.value,
              ),
              false => l10n.allowTitle(request.deviceName),
            },
            detail: switch (request.display) {
              true => _displayAllowBody(l10n),
              false => null,
            },
            needsYou: true,
            tone: .accent,
            trailing: Row(
              mainAxisSize: .min,
              children: [
                if (request.display) ...[
                  const MirroringBetaTag(.secondDisplay),
                  Spacing.h8,
                ],
                Countdown(
                  until: request.deadline,
                  builder: (context, left) => Text(
                    Countdown.clockText(left),
                    style: context.fluffyTheme.typography.caption1.copyWith(
                      color: context.palette.mutedText,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ActivityAction(
                label: switch (request.display) {
                  true => l10n.displayAllow,
                  false => l10n.allow,
                },
                primary: true,
                onPressed: () => viewerViewModel.answer(request, allow: true),
              ),
              ActivityAction(
                label: l10n.dontAllow,
                onPressed: () => viewerViewModel.answer(request, allow: false),
              ),
            ],
          ),
      if (current != null && current.isLive && current.isDisplay)
        ActivityItem(
          id: 'mirroring.live',
          icon: LucideIcons.monitor,
          title: switch (current.startedAt) {
            null => l10n.displayConnectingTitle(current.deviceName),
            _ => l10n.displayShowingTitle(
              current.deviceName,
              DisplayHere.value,
            ),
          },
          detail: switch ((current.startedAt, DisplayHere.isTouch)) {
            (final startedAt?, true) => l10n.displayShowingSince(
              l10n.time(startedAt),
            ),
            (final startedAt?, false) => l10n.displayShowingDetail(
              l10n.time(startedAt),
            ),
            (null, _) => null,
          },
          at: current.startedAt,
          pinned: true,
          tone: .accent,
          onTap: () => unawaited(
            _openDisplay(feature, current.deviceId, current.deviceName),
          ),
          actions: [
            ActivityAction(
              label: l10n.stop,
              onPressed: () => unawaited(viewerViewModel.stop()),
            ),
          ],
        ),
      if (current != null && current.isLive && !current.isDisplay)
        ActivityItem(
          id: 'mirroring.live',
          icon: switch (current.isCamera) {
            true => LucideIcons.video,
            false => LucideIcons.screenShare,
          },
          title: switch ((current.startedAt, current.isCamera)) {
            (null, _) => l10n.viewingAsking(current.deviceName),
            (_, true) => l10n.cameraViewingTitle(current.deviceName),
            (_, false) => l10n.viewingTitle(current.deviceName),
          },
          detail: switch (current.startedAt) {
            final startedAt? => l10n.viewingDetail(
              l10n.time(startedAt),
              l10n.wayName(current.way),
            ),
            null => null,
          },
          at: current.startedAt,
          pinned: true,
          tone: .accent,
          onTap: () => unawaited(_openLive(feature, current)),
          actions: [
            ActivityAction(
              label: l10n.stop,
              onPressed: () => unawaited(viewerViewModel.stop()),
            ),
          ],
        ),
      if (record != null && !(current?.isLive ?? false))
        ActivityItem(
          id: 'mirroring.record.${record.startedAt.millisecondsSinceEpoch}',
          icon: switch (record.camera) {
            true => LucideIcons.video,
            false => LucideIcons.screenShare,
          },
          title: l10n.audit(record),
          at: record.endedAt,
          tone: .muted,
          onDismiss: viewerViewModel.dismissRecord,
        ),
      ..._lendingActivity(l10n),
    ];
  }

  /// This computer's side of lending its desktop: the question waiting
  /// there, the display while it shows, and how the last time ended.
  List<ActivityItem> _lendingActivity(MirroringLocalizations l10n) {
    final display = feature.display;
    if (display == null) {
      return const [];
    }

    final lent = display.current;
    final record = display.lastRecord;
    if (lent != null) {
      final extending = lent.phase == .extending;
      return [
        ActivityItem(
          id: 'mirroring.display',
          icon: LucideIcons.monitor,
          deviceId: lent.deviceId,
          title: switch (lent.phase) {
            .asking => l10n.displayAskingTitle(lent.deviceName),
            .starting => l10n.displayStartingTitle(lent.deviceName),
            .extending => l10n.displayExtendingTitle(
              lent.deviceName,
              ThisComputer.here,
            ),
          },
          detail: switch ((lent.phase, lent.startedAt)) {
            (.asking, _) => l10n.displayAskingBody(lent.deviceName),
            (.extending, final startedAt?) => l10n.displayExtendingDetail(
              l10n.time(startedAt),
            ),
            _ => null,
          },
          at: lent.startedAt,
          pinned: true,
          tone: .accent,
          trailing: switch (lent.answerBy) {
            final until? when lent.phase == .asking => Countdown(
              until: until,
              builder: (context, left) => Text(
                Countdown.clockText(left),
                style: context.fluffyTheme.typography.caption1.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ),
            _ => null,
          },
          actions: [
            ActivityAction(
              label: switch (extending) {
                true => l10n.stop,
                false => l10n.cancel,
              },
              onPressed: () => unawaited(display.stop()),
            ),
          ],
        ),
      ];
    }

    if (record == null) {
      return const [];
    }

    final needsPermission = record.end == .needsScreenRecording;
    return [
      ActivityItem(
        id: 'mirroring.display.${record.at.millisecondsSinceEpoch}',
        icon: switch (needsPermission) {
          true => LucideIcons.monitor,
          false => LucideIcons.monitorOff,
        },
        deviceId: record.deviceId,
        title: l10n.displayEnded(record.deviceName, record.end.name),
        detail: switch (needsPermission) {
          true => l10n.displayScreenRecordingBody,
          false => null,
        },
        at: record.at,
        needsYou: needsPermission,
        tone: switch (needsPermission) {
          true => .warning,
          false => .muted,
        },
        actions: [
          if (needsPermission)
            ActivityAction(
              label: l10n.displayOpenSettings,
              primary: true,
              onPressed: () => unawaited(display.openScreenRecordingSettings()),
            ),
        ],
        onDismiss: display.dismissRecord,
      ),
    ];
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

  /// "Show screen" on every Android phone and tablet, connected or not:
  /// the stage says what to do when it isn't. On an iPhone or iPad too,
  /// where this computer can listen for it.
  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final l10n = context.mirroringL10n;

    return [
      if (_canShow(device))
        FeatureAction(
          id: 'mirroring.show_screen',
          label: l10n.showScreen,
          icon: LucideIcons.screenShare,
          homeOrder: _homeOrder,
          onPressed: () => unawaited(_openMirror(feature, device.device)),
        ),
      if (_canUseCamera(device))
        FeatureAction(
          id: 'mirroring.use_camera',
          label: l10n.useCameraShort,
          tooltip: BetaFeature.wifiCamera.label(
            l10n.useCamera(device.device.name),
            l10n.inBeta,
          ),
          icon: LucideIcons.video,
          onPressed: () => unawaited(_openCamera(feature, device.device)),
        ),
      if (_canLendTo(device)) _displayAction(l10n, device.device),
    ];
  }

  /// "Use MacBook Air as a display", or the way to stop while it is one
  /// or is being asked.
  FeatureAction _displayAction(
    MirroringLocalizations l10n,
    TrustedDevice device,
  ) {
    final display = feature.display;
    final lentHere = display?.current?.deviceId == device.id;

    return FeatureAction(
      id: 'mirroring.use_as_display',
      label: switch (lentHere) {
        true => l10n.displayStopShort,
        false => l10n.displayUseShort,
      },
      tooltip: switch (lentHere) {
        true => l10n.displayStopUsing(device.name),
        false => BetaFeature.secondDisplay.label(
          l10n.displayUse(device.name),
          l10n.inBeta,
        ),
      },
      icon: LucideIcons.monitor,
      onPressed: switch (lentHere) {
        true => () => unawaited(display?.stop()),
        false => () => unawaited(display?.offer(device.id)),
      },
    );
  }

  /// Screen is a section of every device that gets "Show screen": the
  /// launcher, then the stage. Where the stage has no window of its own,
  /// it fills the pane.
  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (!_canShow(device)) {
      return const [];
    }

    final trusted = device.device;
    return [
      FeatureSection(
        id: sectionId,
        title: title(context),
        icon: icon,
        order: 50,
        fillsPane: true,
        builder: (_) => _withViewModels(
          ScreenSectionPage(
            deviceId: trusted.id,
            deviceName: trusted.name,
            onShow: () => unawaited(_openMirror(feature, trusted)),
          ),
        ),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final sections = [
      if (shareViewModel.isAvailable) _shareSettings(),
      if (viewerViewModel.isAvailable && _hasViewerSettings) _viewerSettings(),
    ];
    if (sections.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, section) in sections.indexed) ...[
          if (index > 0) Spacing.v24,
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
      if (viewerViewModel.isAvailable && _hasViewerSettings)
        FeatureSettings(
          group: .phone,
          title: title,
          child: _viewerSettings(),
          summary: switch (viewerViewModel.lookForCable) {
            true => l10n.summaryCable,
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
    final isViewer = _isViewer(device.session);
    final applies = isViewer || !shareViewModel.mayAsk(deviceId);
    final cameraApplies =
        shareViewModel.canSendCamera &&
        (isViewer || !shareViewModel.mayAskCamera(deviceId));
    if (!shareViewModel.isAvailable) {
      return const [];
    }

    final l10n = context.mirroringL10n;
    return [
      if (applies)
        DevicePermission(
          label: l10n.permissionAsk(ThisComputer.handheld),
          detail: switch (shareViewModel.enabled) {
            true => l10n.settingsAllowBody,
            false => l10n.permissionAskOff,
          },
          value: shareViewModel.mayAsk(deviceId),
          onChanged: (value) =>
              unawaited(shareViewModel.setMayAsk(deviceId, value)),
        ),
      if (cameraApplies)
        DevicePermission(
          label: l10n.permissionCameraAsk(ThisComputer.handheld),
          detail: switch (shareViewModel.cameraEnabled) {
            true => l10n.settingsCameraAllowBody,
            false => l10n.permissionCameraAskOff,
          },
          value: shareViewModel.mayAskCamera(deviceId),
          onChanged: (value) =>
              unawaited(shareViewModel.setMayAskCamera(deviceId, value)),
        ),
    ];
  }

  /// Whether [device] gets "Show screen" on this computer.
  bool _canShow(DeviceStatus device) {
    final session = device.session;
    final platform = device.device.platform;
    final shares = session != null && feature.canViewDevice(session);

    return viewerViewModel.isAvailable &&
        (shares || platform == .PLATFORM_ANDROID || _viaAirplay(device.device));
  }

  /// Whether [device] gets "Use its camera" on this computer: a connected
  /// phone that says it can send one. An older Ferret never sees it.
  bool _canUseCamera(DeviceStatus device) {
    final session = device.session;

    return viewerViewModel.isAvailable &&
        session != null &&
        feature.canUseCameraOf(session);
  }

  /// Whether this computer can lend its desktop to [device]: a connected
  /// computer that can be a display.
  bool _canLendTo(DeviceStatus device) {
    final session = device.session;
    return session != null && feature.canExtendTo(session);
  }

  /// An iPhone or iPad shows its screen by picking this computer itself.
  bool _viaAirplay(TrustedDevice device) =>
      device.platform == .PLATFORM_IOS && viewerViewModel.hasReceivers;

  Widget _withViewModels(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: viewerViewModel),
      ChangeNotifierProvider.value(value: stageWindow),
    ],
    child: child,
  );

  Widget _shareSettings() => ChangeNotifierProvider.value(
    value: shareViewModel,
    child: const ShareSettingsFrame(),
  );

  Widget _viewerSettings() => ChangeNotifierProvider.value(
    value: viewerViewModel,
    child: const ViewerSettingsFrame(),
  );

  /// A computer's part is there once it has a switch to show (the cable,
  /// a receiver) or a history to keep. A phone that can be a display has
  /// a viewer too, but its history already shows under what it shares.
  bool get _hasViewerSettings =>
      viewerViewModel.hasCable ||
      viewerViewModel.hasReceivers ||
      (feature.canView && viewerViewModel.history.isNotEmpty);

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
        help: l10n.endTurnedOffBody(name, ThisComputer.here),
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
        reason: l10n.healthShareOff(ThisComputer.handheld),
        help: l10n.healthShareOffHelp,
      );
    }

    if (!shareViewModel.mayAsk(device.id)) {
      return FeatureHealth(
        .off,
        reason: l10n.healthShareBlocked(name),
        help: l10n.healthShareBlockedHelp(name, ThisComputer.handheld),
      );
    }

    if (!shareViewModel.canCapture) {
      return FeatureHealth(
        .off,
        reason: l10n.settingsUnsupported(ThisComputer.handheld),
      );
    }

    if (shareViewModel.active?.deviceId == device.id) {
      return FeatureHealth(
        .ok,
        reason: l10n.healthSharing(ThisComputer.handheld),
      );
    }

    return FeatureHealth(.ok, reason: l10n.healthShareAsks);
  }

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _revealOnAsk?.cancel();
    await _openOnIncoming?.cancel();
    await _askOnRequest?.cancel();
    await _openOnDisplay?.cancel();
    await _noticeResponses?.cancel();
    await _controlNotices?.cancel();
    await _controlResponses?.cancel();
    await _cameraNotices?.cancel();
    await _cameraResponses?.cancel();
    await _displayNotices?.cancel();
    await _displayResponses?.cancel();
    _changes.dispose();
    stageWindow.dispose();
    viewerViewModel.dispose();
    shareViewModel.dispose();
  }

  /// On the phone: the question while a computer asks to control it, and
  /// "Being controlled by MacBook" with Stop for as long as it does.
  void _syncControlNotices(FeatureContext context) {
    final control = feature.source?.control;
    final pending = control?.pending;
    final controller = control?.controller;
    final l10n = platformMirroringL10n();
    if (!identical(pending, _controlAskShown)) {
      _controlAskShown = pending;
      _showOrCancel(context, _controlAskNotice, switch (pending) {
        final asking? => LocalNotice(
          id: _controlAskNotice,
          channel: .incoming,
          title: l10n.controlAskTitle(
            asking.deviceName,
            feature.host.localDevice.name,
          ),
          body: l10n.controlAskBody(asking.deviceName),
          category: _controlAskCategory,
          public: true,
        ),
        null => null,
      });
      if (pending != null) {
        unawaited(context.reveal());
      }
    }

    if (identical(controller, _controlledShown)) {
      return;
    }

    _controlledShown = controller;
    _showOrCancel(context, _controlledNotice, switch (controller) {
      final controlling? => LocalNotice(
        id: _controlledNotice,
        channel: .incoming,
        title: l10n.controlledTitle(controlling.deviceName),
        body: l10n.controlledBody,
        category: _controlledCategory,
        silent: true,
        ongoing: true,
        public: true,
      ),
      null => null,
    });
  }

  /// On the phone: the question while a computer asks for its camera.
  /// "Camera on for MacBook" with Stop is Android's own ongoing notice,
  /// from the service that keeps the camera open.
  void _syncCameraNotice(FeatureContext context) {
    final pending = feature.camera?.pending;
    if (identical(pending, _cameraAskShown)) {
      return;
    }

    _cameraAskShown = pending;
    final l10n = platformMirroringL10n();
    _showOrCancel(context, _cameraAskNotice, switch (pending) {
      final asking? => LocalNotice(
        id: _cameraAskNotice,
        channel: .incoming,
        title: l10n.cameraAskTitle(asking.deviceName),
        body: l10n.cameraAskBody,
        category: _cameraAskCategory,
      ),
      null => null,
    });
    if (pending != null) {
      unawaited(context.reveal());
    }
  }

  void _onCameraResponse(NoticeResponse response) {
    final choice = switch (response.actionId) {
      _cameraOnceAction => ControlChoice.once,
      _cameraAlwaysAction => ControlChoice.always,
      _cameraNoAction => ControlChoice.no,
      _ => null,
    };
    if (choice != null) {
      unawaited(feature.camera?.answer(choice));
    }
  }

  /// On a phone or tablet that is another computer's display: "This
  /// phone is MacBook's display" with Stop for as long as it is, so it
  /// can be stopped or brought back from anywhere.
  void _syncDisplayNotice(FeatureContext context) {
    final current = feature.viewer?.current;
    final showing = switch (current) {
      final session? when session.isDisplay && session.isLive => session,
      _ => null,
    };
    if (showing?.target == _displayNoticeShown) {
      return;
    }

    _displayNoticeShown = showing?.target;
    final l10n = platformMirroringL10n();
    _showOrCancel(context, _displayingNotice, switch (showing) {
      final session? => LocalNotice(
        id: _displayingNotice,
        channel: .incoming,
        title: l10n.displayingTitle(ThisComputer.handheld, session.deviceName),
        body: l10n.displayingBody,
        category: _displayingCategory,
        silent: true,
        ongoing: true,
        public: true,
      ),
      null => null,
    });
  }

  /// Stop ends the display where the notice is; a tap brings it back.
  void _onDisplayResponse(FeatureContext context, NoticeResponse response) {
    final current = feature.viewer?.current;
    if (current == null || !current.isDisplay || !current.isLive) {
      return;
    }

    if (response.actionId == _stopDisplayAction) {
      unawaited(viewerViewModel.stop());
      final page = _displayPage;
      if (page != null && page.isActive) {
        page.navigator?.removeRoute(page);
      }

      return;
    }

    if (response.actionId != null) {
      return;
    }

    unawaited(context.reveal());
    unawaited(_openDisplay(context, current.deviceId, current.deviceName));
  }

  void _showOrCancel(FeatureContext context, String id, LocalNotice? notice) {
    if (notice == null) {
      unawaited(context.notifier.cancel(id));
      return;
    }

    unawaited(context.notifier.show(notice));
  }

  void _onControlResponse(NoticeResponse response) {
    final control = feature.source?.control;
    final choice = switch (response.actionId) {
      _onceAction => ControlChoice.once,
      _alwaysAction => ControlChoice.always,
      _noAction => ControlChoice.no,
      _ => null,
    };
    if (choice != null) {
      unawaited(control?.answer(choice));
      return;
    }

    if (response.actionId == _stopControlAction) {
      unawaited(control?.stop());
    }
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

  /// Opens the stage for a paired device and starts the best way there
  /// is to show it.
  Future<void> _openMirror(FeatureContext context, TrustedDevice device) async {
    final opened = _openStage(context, device.id, device.name);
    if (_viaAirplay(device)) {
      unawaited(viewerViewModel.openAirplayGuide(device.id));
    }

    if (!_viaAirplay(device)) {
      unawaited(viewerViewModel.show(device.id, device.name));
    }

    await opened;
  }

  /// Opens the stage for a phone's camera and asks the phone for it.
  Future<void> _openCamera(FeatureContext context, TrustedDevice device) async {
    final opened = _openStage(context, device.id, device.name, camera: true);
    unawaited(viewerViewModel.showCamera(device.id, device.name));
    await opened;
  }

  /// Back to the stage of what is shown right now.
  Future<void> _openLive(FeatureContext context, ViewSession session) =>
      _openStage(
        context,
        session.deviceId,
        session.deviceName,
        camera: session.isCamera,
      );

  Future<void> _showTarget(FeatureContext context, MirrorTarget target) async {
    final opened = _openPage(context, target);
    unawaited(viewerViewModel.showTarget(target));
    await opened;
  }

  /// A device started showing its screen here by itself: the viewer
  /// already plays it, so the page only has to come up. One that was
  /// asked for from its own page shows there.
  Future<void> _openIncoming(
    FeatureContext context,
    MirrorTarget target,
  ) async {
    unawaited(viewerViewModel.refreshWindow());
    if (viewerViewModel.airplayGuideFor != null) {
      return;
    }

    unawaited(context.reveal());
    await _openPage(context, target);
  }

  /// Puts each device's question in front of the owner once: as a line
  /// that needs them and a notice, or on the stage that asked for it.
  void _askWhenRequested(FeatureContext context) {
    final requests = feature.routes?.requests ?? const <IncomingRequest>[];
    final hadAny = _asked.isNotEmpty;
    _asked.retainAll(requests);
    if (hadAny && _asked.isEmpty) {
      unawaited(context.notifier.cancel(_requestNotice));
    }

    for (final request in requests) {
      if (_asked.add(request)) {
        _ask(context, request);
      }
    }
  }

  void _ask(FeatureContext context, IncomingRequest request) {
    unawaited(context.reveal());
    if (viewerViewModel.airplayGuideFor != null) {
      return;
    }

    final l10n = platformMirroringL10n();
    unawaited(
      context.notifier.show(
        LocalNotice(
          id: _requestNotice,
          channel: .incoming,
          title: switch (request.display) {
            true => l10n.displayAllowTitle(
              request.deviceName,
              DisplayHere.value,
            ),
            false => l10n.allowTitle(request.deviceName),
          },
          body: switch (request.display) {
            true => _displayAllowBody(l10n),
            false => l10n.allowNoticeBody,
          },
          category: switch (request.display) {
            true => _displayRequestCategory,
            false => _requestCategory,
          },
        ),
      ),
    );
  }

  void _onNoticeResponse(NoticeResponse response) {
    final request = viewerViewModel.requests.firstOrNull;
    final actionId = response.actionId;
    if (request == null || actionId == null) {
      return;
    }

    viewerViewModel.answer(request, allow: actionId == _showAction);
  }

  /// What saying yes means here: the mouse and keyboard on a computer,
  /// the fingers on a phone or tablet.
  String _displayAllowBody(MirroringLocalizations l10n) =>
      switch (DisplayHere.isTouch) {
        true => l10n.displayAllowBodyTouch,
        false => l10n.displayAllowBody,
      };

  /// The owner let a computer use this one as its display: its window
  /// comes up full screen, once per time.
  void _openDisplayWhenAllowed(FeatureContext context) {
    final current = feature.viewer?.current;
    final starts =
        current != null &&
        current.isDisplay &&
        current.isLive &&
        current.startedAt == null;
    if (!starts) {
      return;
    }

    final open =
        stageWindow.deviceId != null || (_displayPage?.isActive ?? false);
    if (_displayShown == current.target && open) {
      return;
    }

    _displayShown = current.target;
    unawaited(context.reveal());
    unawaited(_openDisplay(context, current.deviceId, current.deviceName));
  }

  /// Another computer's display, full screen in a window of its own, or
  /// as a page where there is no such window.
  Future<void> _openDisplay(
    FeatureContext context,
    String deviceId,
    String deviceName,
  ) async {
    final l10n = platformMirroringL10n();
    final opened = await stageWindow.open(
      deviceId: deviceId,
      title: l10n.displayWindowTitle(deviceName),
      shape: StageWindowViewModel.displayShape,
      fullScreen: true,
      builder: (_) => _withViewModels(
        DisplayWindowPage(
          deviceId: deviceId,
          deviceName: deviceName,
          onClose: () => unawaited(stageWindow.close()),
        ),
      ),
    );
    if (opened) {
      return;
    }

    final navigator = context.navigatorKey.currentState;
    if (navigator == null || (_displayPage?.isActive ?? false)) {
      return;
    }

    final page = PageRouteBuilder<void>(
      pageBuilder: (pageContext, _, _) => _withViewModels(
        DisplayWindowPage(
          deviceId: deviceId,
          deviceName: deviceName,
          onClose: () {
            final route = ModalRoute.of(pageContext);
            if (route == null || !route.isActive) {
              return;
            }

            // Past the page's own "Stop being its display?" on Back.
            if (route.isCurrent) {
              Navigator.of(pageContext).pop();
              return;
            }

            Navigator.of(pageContext).removeRoute(route);
          },
        ),
      ),
    );
    _displayPage = page;
    await navigator.push(page);
  }

  Future<void> _openPage(FeatureContext context, MirrorTarget target) =>
      _openStage(context, ViewSession.deviceIdOf(target), target.name);

  /// Puts the stage for a device in front of the person: in a window of
  /// its own where there is one. Elsewhere a paired device has its Screen
  /// section, pushed on a small view and selected next to the device list
  /// in a window; a phone that isn't paired has no section, so its stage
  /// is a page of its own.
  Future<void> _openStage(
    FeatureContext context,
    String deviceId,
    String deviceName, {
    bool camera = false,
  }) async {
    if (await _openWindow(deviceId, deviceName, camera: camera)) {
      return;
    }

    final isPaired = context.engine.devices.any(
      (status) => status.device.id == deviceId,
    );
    if (!isPaired) {
      await _pushPage(context, deviceId, deviceName);
      return;
    }

    viewerViewModel.openStage(deviceId);
    await context.openSection(deviceId, sectionId);
  }

  /// Opens the mirror page for a device, in place of the one that is
  /// open for another. The same device's page just stays.
  Future<void> _pushPage(
    FeatureContext context,
    String deviceId,
    String deviceName,
  ) async {
    final navigator = context.navigatorKey.currentState;
    final open = _page;
    if (navigator == null) {
      return;
    }

    if (open != null && open.isActive && _pageDeviceId == deviceId) {
      return;
    }

    final route = PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => ChangeNotifierProvider.value(
        value: viewerViewModel,
        child: MirrorPage(deviceId: deviceId, deviceName: deviceName),
      ),
    );
    _page = route;
    _pageDeviceId = deviceId;
    viewerViewModel.openStage(deviceId);
    final pushed = navigator.push(route);
    if (open != null && open.isActive) {
      navigator.removeRoute(open);
    }

    await pushed;
    if (identical(_page, route)) {
      _page = null;
      _pageDeviceId = null;
    }
  }

  /// The stage in a window in the phone's shape. The stage is said to be
  /// this device's before the window is there, so the one it replaces
  /// leaves everything alone as it goes.
  Future<bool> _openWindow(
    String deviceId,
    String deviceName, {
    bool camera = false,
  }) async {
    if (!stageWindow.canOpen) {
      return false;
    }

    final l10n = platformMirroringL10n();
    viewerViewModel.openStage(deviceId);
    return stageWindow.open(
      deviceId: deviceId,
      title: switch (camera) {
        true => l10n.cameraWindowTitle(deviceName),
        false => l10n.windowTitle(deviceName),
      },
      shape: switch (camera) {
        true => StageWindowViewModel.cameraShape,
        false => StageWindowViewModel.firstShape,
      },
      barHeight: MirrorWindowBar.height,
      builder: (_) => _withViewModels(
        MirrorWindowPage(
          deviceId: deviceId,
          deviceName: deviceName,
          onClose: () => unawaited(stageWindow.close()),
        ),
      ),
    );
  }

  CameraTexts _cameraNoticeTexts(String deviceName, {bool withSound = false}) {
    final l10n = platformMirroringL10n();
    return CameraTexts(
      title: l10n.cameraOnTitle(deviceName),
      body: switch (withSound) {
        true => l10n.noticeCameraBody(ThisComputer.handheld),
        false => l10n.noticeCameraBodySilent(ThisComputer.handheld),
      },
      stopLabel: l10n.stop,
      channelName: l10n.noticeCameraChannel,
    );
  }

  ConsentTexts _noticeTexts(String deviceName, {bool withSound = false}) {
    final l10n = platformMirroringL10n();
    return ConsentTexts(
      askTitle: l10n.askingTitle(deviceName),
      askBody: l10n.noticeAskBody,
      askChannelName: l10n.noticeAskChannel,
      sharingTitle: switch (withSound) {
        true => l10n.sharingTitleSound(deviceName),
        false => l10n.sharingTitle(deviceName),
      },
      sharingBody: switch (withSound) {
        true => l10n.noticeSharingBodySound,
        false => l10n.noticeSharingBody,
      },
      stopLabel: l10n.stop,
      sharingChannelName: l10n.noticeSharingChannel,
    );
  }
}
