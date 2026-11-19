import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:fixnum/fixnum.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/notifications.dart';
import 'package:protocol/protocol.dart';

/// The engine side of notification mirroring.
///
/// A device with a [source] (an Android phone) sends its new notifications to
/// connected receivers, never the ones that were already showing, and runs
/// the actions and dismissals they send back. Every other device receives
/// them and reports what happens on [mirrorEvents].
class NotificationsFeature extends Feature implements MirrorControl {
  NotificationsFeature({this.source, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const featureId = 'notifications';

  /// Flag of a device that sends its notifications.
  static const sendFlag = 'send';

  /// Flag of a device that shows another device's notifications.
  static const receiveFlag = 'receive';

  static const _maxTitleLength = 200;
  static const _maxTextLength = 2000;

  final NotificationSource? source;
  final DateTime Function() _clock;

  final Map<String, ReceiverState> _receivers = {};
  final Map<String, MirrorSettings> _senderSettings = {};
  final Set<String> _unreachableSenders = {};
  final Map<String, Uint8List> _icons = {};
  final Map<String, int> _lastPostedByApp = {};
  final StreamController<MirrorEvent> _mirrorEvents = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  // Source events run one at a time, so a quick removal never overtakes the
  // post it removes.
  Future<void> _sourceQueue = Future.value();

  late final MirrorPreferences preferences = MirrorPreferences(host.settings);

  /// What this computer remembers about its phones.
  late final ReceiverPreferences receiverPreferences = ReceiverPreferences(
    host.settings,
  );

  @override
  String get id => featureId;

  @override
  List<String> get flags => switch (isSource) {
    true => const [sendFlag],
    false => const [receiveFlag],
  };

  /// This device mirrors its own notifications to others.
  bool get isSource => source != null;

  @override
  Stream<MirrorEvent> get mirrorEvents => _mirrorEvents.stream;

  /// The last known settings of each connected phone, by device id.
  Map<String, MirrorSettings> get senderSettings =>
      Map.unmodifiable(_senderSettings);

  /// Whether the phone [deviceId] didn't answer the last settings request.
  bool isUnreachable(String deviceId) => _unreachableSenders.contains(deviceId);

  /// Whether [deviceId] is connected right now.
  bool isConnected(String deviceId) => host.sessionFor(deviceId) != null;

  /// Connected devices that mirror their notifications here.
  List<Session> get senders => [
    for (final session in host.sessions)
      if (_hasFlag(session, sendFlag)) session,
  ];

  @override
  Future<void> onStart() async {
    if (source case final notificationSource?) {
      unawaited(_migrateAppFilter(notificationSource));
      _subscriptions
        ..add(notificationSource.events.listen(_onSourceEvent))
        ..add(
          host.settings.changes
              .where(MirrorPreferences.owns)
              .listen((_) => unawaited(_pushSettings())),
        );
    }
  }

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _mirrorEvents.close();
  }

  @override
  void onSessionOpened(Session session) {
    if (isSource && _hasFlag(session, receiveFlag)) {
      _openReceiver(session);
      return;
    }

    if (!isSource && _hasFlag(session, sendFlag)) {
      unawaited(fetchSettings(session.remoteDeviceId));
    }
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    _receivers[deviceId]?.disconnect();

    if (!isSource && _hasFlag(session, sendFlag)) {
      _senderSettings.remove(deviceId);
      _unreachableSenders.remove(deviceId);
      _emit(MirrorSourceGone(deviceId));
    }
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    final deviceId = session.remoteDeviceId;

    if (payloadOf(envelope, NotificationPosted.new) case final posted?) {
      if (receiverPreferences.showsFrom(deviceId)) {
        _onMirrorPosted(deviceId, posted.notification);
      }

      return null;
    }

    if (payloadOf(envelope, NotificationRemoved.new) case final removed?) {
      _emit(MirrorRemoved(deviceId, removed.key));
      return null;
    }

    if (payloadOf(envelope, CatchUp.new) case final catchUp?) {
      if (!receiverPreferences.showsFrom(deviceId)) {
        return null;
      }

      _emit(
        MirrorCaughtUp(
          deviceId,
          missedCount: catchUp.missedCount,
          activeKeys: catchUp.activeKeys.toSet(),
          missedAppNames: catchUp.missedAppNames,
        ),
      );
      return null;
    }

    if (payloadOf(envelope, MirrorSettings.new) case final settings?) {
      _onSenderSettings(deviceId, settings);
      return null;
    }

    return _onSourceRequest(session, envelope);
  }

  /// Returns false when the phone is gone or the notification no longer has
  /// the action.
  @override
  Future<bool> invokeAction(
    String deviceId,
    String key,
    String actionId, {
    String? replyText,
  }) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return false;
    }

    final request = InvokeAction(key: key, actionId: actionId);
    if (replyText case final text?) {
      request.replyText = text;
    }

    try {
      final result = await session.call(
        featureId,
        request,
        InvokeActionResult.new,
      );
      return result.ok;
    } on Object catch (error) {
      printWarning('Running a notification action on $deviceId failed', error);
      return false;
    }
  }

  /// Returns false when the phone is not connected.
  @override
  Future<bool> dismiss(String deviceId, String key) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return false;
    }

    try {
      await session.send(featureId, DismissNotification(key: key));
      return true;
    } on Object catch (error) {
      printWarning('Dismissing a notification on $deviceId failed', error);
      return false;
    }
  }

  /// Reads the mirroring settings of the phone [deviceId]. Returns null and
  /// marks it unreachable when it doesn't answer.
  Future<MirrorSettings?> fetchSettings(String deviceId) async {
    try {
      final settings = await _requireSession(
        deviceId,
      ).call(featureId, MirrorSettingsRequest(), MirrorSettings.new);
      _onSenderSettings(deviceId, settings);
      return settings;
    } on Object catch (error) {
      printDebug('Mirroring settings of $deviceId not read: $error');
      _unreachableSenders.add(deviceId);
      _emit(MirrorSettingsUnavailable(deviceId));
      return null;
    }
  }

  /// The apps of the phone [deviceId], for the app picker.
  Future<List<AppEntry>> fetchApps(String deviceId) async {
    final response = await _requireSession(deviceId).call(
      featureId,
      AppListRequest(),
      AppListResponse.new,
      timeout: const Duration(seconds: 30),
    );
    return response.apps;
  }

  /// Changes the mirroring settings of the phone [deviceId].
  Future<MirrorSettings> updateSettings(
    String deviceId,
    UpdateMirrorSettings update,
  ) async {
    final settings = await _requireSession(
      deviceId,
    ).call(featureId, update, MirrorSettings.new);
    _onSenderSettings(deviceId, settings);
    return settings;
  }

  /// This phone's mirroring settings.
  Future<MirrorSettings> localSettings() async {
    final accessGranted = await _isAccessGranted();

    return MirrorSettings(
      enabled: preferences.enabled,
      accessGranted: accessGranted,
      skipWhileUsing: preferences.skipWhileUsing,
      appFilter: preferences.appFilter,
      allowedPackages: preferences.allowedApps.toList()..sort(),
      excludedPackages: preferences.excludedApps.toList()..sort(),
    );
  }

  /// This phone's apps, with whether each comes through and when it last
  /// posted.
  Future<List<AppEntry>> localApps() async {
    final notificationSource = source;
    if (notificationSource == null) {
      return const [];
    }

    final apps = await notificationSource.listApps();
    return [
      for (final app in apps)
        AppEntry(
          package: app.packageName,
          name: app.name,
          iconPng: app.icon,
          allowed: preferences.isAllowed(app.packageName),
          isMessaging: MessagingApps.contains(app.packageName),
          lastPostedMs: Int64(_lastPosted(app)),
        ),
    ];
  }

  /// Applies [update] to this phone's settings.
  Future<MirrorSettings> applySettings(UpdateMirrorSettings update) async {
    if (update.hasAppFilter()) {
      await preferences.setAppFilter(update.appFilter);
    }

    await preferences.setAllowed({
      for (final choice in update.apps) choice.package: choice.allowed,
    });
    if (update.hasSkipWhileUsing()) {
      await preferences.setSkipWhileUsing(update.skipWhileUsing);
    }

    return localSettings();
  }

  Future<GeneratedMessage?> _onSourceRequest(
    Session session,
    Envelope envelope,
  ) async {
    final notificationSource = source;
    if (notificationSource == null) {
      if (envelope.expectsReply) {
        await session.replyError(envelope, .ERROR_CODE_UNSUPPORTED);
      }

      return null;
    }

    if (payloadOf(envelope, InvokeAction.new) case final request?) {
      final ok = await notificationSource.invokeAction(
        request.key,
        request.actionId,
        replyText: switch (request.hasReplyText()) {
          true => request.replyText,
          false => null,
        },
      );
      return InvokeActionResult(ok: ok);
    }

    if (payloadOf(envelope, DismissNotification.new) case final dismiss?) {
      await notificationSource.cancel(dismiss.key);
      return null;
    }

    if (payloadOf(envelope, MirrorSettingsRequest.new) != null) {
      return localSettings();
    }

    if (payloadOf(envelope, AppListRequest.new) != null) {
      return AppListResponse(apps: await localApps());
    }

    if (payloadOf(envelope, UpdateMirrorSettings.new) case final update?) {
      return applySettings(update);
    }

    return null;
  }

  void _openReceiver(Session session) {
    final state = _receivers.putIfAbsent(
      session.remoteDeviceId,
      ReceiverState.new,
    );
    final catchUp = CatchUp(
      missedCount: state.missed.length,
      activeKeys: state.forwarded.keys,
      missedAppNames: state.missed.values.toSet(),
    );

    state.connect(_clock().millisecondsSinceEpoch);
    _send(session, catchUp);
  }

  void _onSourceEvent(NotificationEvent event) {
    _sourceQueue = _sourceQueue.then(
      (_) => _handleSourceEvent(event).catchError((Object error) {
        printWarning('Handling a phone notification failed', error);
      }),
    );
  }

  Future<void> _handleSourceEvent(NotificationEvent event) async {
    switch (event) {
      case NotificationPostedEvent(:final notification):
        _lastPostedByApp[notification.packageName] = notification.postedAtMs;
        await _onPosted(notification);
      case NotificationRemovedEvent(:final key):
        _onRemoved(key);
      case ListenerChangedEvent():
        await _pushSettings();
    }
  }

  Future<void> _onPosted(PlatformNotification notification) async {
    if (_receivers.isEmpty) {
      return;
    }

    if (ForwardPolicy.decide(notification, preferences) != .forward) {
      return;
    }

    if (preferences.skipWhileUsing && await _isDeviceInUse()) {
      return;
    }

    final hash = ForwardPolicy.contentHash(notification);
    final key = notification.key;
    for (final MapEntry(key: deviceId, value: state) in _receivers.entries) {
      if (state.forwarded[key] == hash) {
        continue;
      }

      final connectedSince = state.connectedSinceMs;
      if (connectedSince == null) {
        state.forwarded.remove(key);
        state.missed[key] = notification.appName;
        continue;
      }

      if (notification.postedAtMs < connectedSince) {
        continue;
      }

      final session = host.sessionFor(deviceId);
      if (session == null) {
        continue;
      }

      final sendIcon =
          notification.appIcon != null &&
          state.iconsSent.add(notification.packageName);
      state.forwarded[key] = hash;
      _send(
        session,
        NotificationPosted(
          notification: _itemOf(notification, withIcon: sendIcon),
        ),
      );
    }
  }

  void _onRemoved(String key) {
    for (final MapEntry(key: deviceId, value: state) in _receivers.entries) {
      final wasSent = state.remove(key);
      if (!wasSent || !state.isConnected) {
        continue;
      }

      if (host.sessionFor(deviceId) case final session?) {
        _send(session, NotificationRemoved(key: key));
      }
    }
  }

  Future<void> _pushSettings() async {
    final receivers = [
      for (final MapEntry(key: deviceId, value: state) in _receivers.entries)
        if (state.isConnected) ?host.sessionFor(deviceId),
    ];
    if (receivers.isEmpty) {
      return;
    }

    final settings = await localSettings();
    for (final session in receivers) {
      _send(session, settings);
    }
  }

  void _onSenderSettings(String deviceId, MirrorSettings settings) {
    _senderSettings[deviceId] = settings;
    _unreachableSenders.remove(deviceId);
    unawaited(receiverPreferences.setMirroring(deviceId, settings.enabled));
    _emit(MirrorSettingsChanged(deviceId, settings));
  }

  void _onMirrorPosted(String deviceId, NotificationItem item) {
    final iconKey = '$deviceId/${item.appPackage}';
    if (item.appIconPng.isNotEmpty) {
      _icons[iconKey] = Uint8List.fromList(item.appIconPng);
    }

    _emit(
      MirrorPosted(
        deviceId,
        MirroredNotification(
          deviceId: deviceId,
          key: item.key,
          appPackage: item.appPackage,
          appName: item.appName,
          title: item.title,
          text: item.text,
          textHidden: item.textHidden,
          postedAt: .fromMillisecondsSinceEpoch(item.postedAtMs.toInt()),
          isConversation: item.isConversation,
          actions: [
            for (final action in item.actions)
              MirroredAction(
                id: action.id,
                title: action.title,
                isReply: action.isReply,
              ),
          ],
          appIcon: _icons[iconKey],
        ),
      ),
    );
  }

  NotificationItem _itemOf(
    PlatformNotification notification, {
    required bool withIcon,
  }) {
    final hidesCode =
        preferences.hideCodes &&
        OneTimeCode.isIn('${notification.title}\n${notification.text}');
    final item = NotificationItem(
      key: notification.key,
      appPackage: notification.packageName,
      appName: notification.appName,
      title: switch (hidesCode && OneTimeCode.isIn(notification.title)) {
        true => '',
        false => _clip(notification.title, _maxTitleLength),
      },
      text: switch (hidesCode) {
        true => '',
        false => _clip(notification.text, _maxTextLength),
      },
      textHidden: hidesCode,
      postedAtMs: Int64(notification.postedAtMs),
      isConversation: notification.isConversation,
      actions: [
        for (final action in notification.actions)
          NotificationAction(
            id: action.id,
            title: action.title,
            isReply: action.isReply,
          ),
      ],
    );
    if (notification.appIcon case final icon? when withIcon) {
      item.appIconPng = icon;
    }

    return item;
  }

  int _lastPosted(PlatformApp app) {
    final seen = _lastPostedByApp[app.packageName] ?? 0;
    final showing = app.lastPostedMs ?? 0;
    return switch (seen > showing) {
      true => seen,
      false => showing,
    };
  }

  Future<void> _migrateAppFilter(NotificationSource notificationSource) async {
    if (!preferences.needsMigration) {
      return;
    }

    try {
      final apps = await notificationSource.listApps();
      await preferences.migrate({
        for (final app in apps)
          if (MessagingApps.contains(app.packageName)) app.packageName,
      });
    } on Object catch (error) {
      printWarning('Reading the apps for the app filter failed', error);
    }
  }

  Session _requireSession(String deviceId) {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      throw const SessionClosedException();
    }

    return session;
  }

  Future<bool> _isAccessGranted() async {
    try {
      return await source?.isAccessGranted() ?? false;
    } on Object catch (error) {
      printWarning('Reading notification access failed', error);
      return false;
    }
  }

  Future<bool> _isDeviceInUse() async {
    try {
      return await source?.isDeviceInUse() ?? false;
    } on Object catch (error) {
      printWarning('Reading whether the phone is in use failed', error);
      return false;
    }
  }

  void _send(Session session, GeneratedMessage message) => unawaited(
    session.send(featureId, message).catchError((Object error) {
      printDebug('Notifications message to ${session.remoteDeviceId} lost');
    }),
  );

  void _emit(MirrorEvent event) {
    if (!_mirrorEvents.isClosed) {
      _mirrorEvents.add(event);
    }
  }

  static bool _hasFlag(Session session, String flag) =>
      session.remoteFeature(featureId)?.flags.contains(flag) ?? false;

  static String _clip(String value, int maxLength) =>
      switch (value.length > maxLength) {
        true => '${value.substring(0, maxLength - 1)}…',
        false => value,
      };
}
