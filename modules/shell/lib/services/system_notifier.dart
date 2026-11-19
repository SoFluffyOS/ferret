import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shell/l10n/l10n.dart';

/// The app's one [LocalNotifier], on the platform notification centre.
class SystemNotifier implements LocalNotifier {
  SystemNotifier._(this._plugin, this._categories);

  static const _windowsGuid = '5b8f9a4e-3c1d-4e2a-9f6b-7d0c1e2a3b4c';
  static const _linuxIcon = 'io.sofluffy.ferret';

  /// Windows reads a toast's icon from a file: the ferret the shell bundles
  /// as an asset, next to the app.
  static String _windowsIconPath() {
    final folder = File(Platform.resolvedExecutable).parent.path;
    return [
      folder,
      'data',
      'flutter_assets',
      'packages',
      'shell',
      'assets',
      'notice_icon.png',
    ].join(Platform.pathSeparator);
  }

  static Future<SystemNotifier> create(List<NoticeCategory> categories) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final notifier = SystemNotifier._(plugin, {
      for (final category in categories) category.id: category,
    });

    try {
      await plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings(
            '@drawable/ic_stat_ferret',
          ),
          iOS: notifier._darwinSettings(),
          macOS: notifier._darwinSettings(),
          linux: LinuxInitializationSettings(
            defaultActionName: _l10n().menuOpen,
            defaultIcon: ThemeLinuxIcon(_linuxIcon),
          ),
          windows: WindowsInitializationSettings(
            appName: 'Ferret',
            appUserModelId: 'io.sofluffy.ferret',
            guid: _windowsGuid,
            iconPath: _windowsIconPath(),
          ),
        ),
        onDidReceiveNotificationResponse: notifier._onResponse,
      );
    } on Object catch (error) {
      printWarning('Notifications are unavailable', error);
    }

    return notifier;
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<String, NoticeCategory> _categories;
  final StreamController<NoticeResponse> _responses = .broadcast();

  @override
  Stream<NoticeResponse> get responses => _responses.stream;

  @override
  Future<void> show(LocalNotice notice) async {
    final category = _categories[notice.category];
    final actions = category?.actions ?? const <NoticeAction>[];

    try {
      await _plugin.show(
        id: _numericId(notice.id),
        title: notice.title,
        body: notice.body,
        payload: notice.id,
        notificationDetails: NotificationDetails(
          android: _android(notice, actions),
          macOS: _darwin(notice),
          iOS: _darwin(notice),
          linux: LinuxNotificationDetails(
            actions: [
              for (final action in actions)
                LinuxNotificationAction(key: action.id, label: action.label),
            ],
          ),
          windows: WindowsNotificationDetails(
            actions: [
              for (final action in actions)
                WindowsAction(
                  content: action.label,
                  arguments: action.id,
                  inputId: _inputIdFor(action),
                ),
            ],
            inputs: [
              for (final action in actions)
                if (action.isReply)
                  WindowsTextInput(
                    id: action.id,
                    placeHolderContent: action.label,
                  ),
            ],
          ),
        ),
      );
    } on Object catch (error) {
      printWarning('Could not show a notification', error);
    }
  }

  @override
  Future<void> cancel(String id) async {
    try {
      await _plugin.cancel(id: _numericId(id));
    } on Object catch (error) {
      printDebug('Could not cancel notification $id: $error');
    }
  }

  DarwinInitializationSettings _darwinSettings() =>
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          for (final category in _categories.values)
            DarwinNotificationCategory(
              category.id,
              actions: [
                for (final action in category.actions)
                  switch (action.isReply) {
                    true => DarwinNotificationAction.text(
                      action.id,
                      action.label,
                      buttonTitle: action.label,
                      placeholder: action.label,
                    ),
                    false => DarwinNotificationAction.plain(
                      action.id,
                      action.label,
                    ),
                  },
              ],
            ),
        ],
      );

  /// Asks for permission to show notifications, where the platform needs it.
  Future<void> requestPermission() async {
    if (Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true);
      return;
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true);
      return;
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  AndroidNotificationDetails _android(
    LocalNotice notice,
    List<NoticeAction> actions,
  ) {
    final (importance, priority) = switch (notice.channel) {
      .find => (Importance.max, Priority.max),
      .incoming => (Importance.high, Priority.high),
      .problems ||
      .transfers => (Importance.defaultImportance, Priority.defaultPriority),
      .suggestions => (Importance.low, Priority.low),
    };

    return AndroidNotificationDetails(
      'ferret.${notice.channel.name}',
      _channelName(notice.channel),
      importance: importance,
      priority: priority,
      groupKey: notice.groupKey,
      silent: notice.silent,
      onlyAlertOnce: notice.progress != null || notice.ongoing,
      ongoing: notice.ongoing,
      autoCancel: !notice.ongoing,
      showProgress: notice.progress != null,
      maxProgress: 100,
      progress: ((notice.progress ?? 0) * 100).round(),
      largeIcon: switch (notice.image) {
        final image? => ByteArrayAndroidBitmap(image),
        null => null,
      },
      actions: [
        for (final action in actions)
          AndroidNotificationAction(
            action.id,
            action.label,
            inputs: switch (action.isReply) {
              true => [AndroidNotificationActionInput(label: action.label)],
              false => const [],
            },
          ),
      ],
    );
  }

  DarwinNotificationDetails _darwin(LocalNotice notice) =>
      DarwinNotificationDetails(
        categoryIdentifier: notice.category,
        threadIdentifier: notice.groupKey,
        presentSound: !notice.silent,
      );

  String _channelName(NoticeChannel channel) {
    final l10n = _l10n();
    return switch (channel) {
      .transfers => l10n.noticeChannelTransfers,
      .incoming => l10n.noticeChannelIncoming,
      .suggestions => l10n.noticeChannelSuggestions,
      .find => l10n.noticeChannelFind,
      .problems => l10n.noticeChannelProblems,
    };
  }

  static ShellLocalizations _l10n() => lookupShellLocalizations(
    AppLocale.pick(ShellLocalizations.supportedLocales),
  );

  String? _inputIdFor(NoticeAction action) => switch (action.isReply) {
    true => action.id,
    false => null,
  };

  void _onResponse(NotificationResponse response) {
    final noticeId = response.payload;
    if (noticeId == null) {
      return;
    }

    final actionId = switch (response.actionId) {
      final id? when id.isNotEmpty => id,
      _ => null,
    };
    _responses.add(
      NoticeResponse(
        noticeId: noticeId,
        actionId: actionId,
        replyText: response.input,
      ),
    );
  }

  /// Notification ids are 32-bit ints; fold the string id into one, the same
  /// on every run.
  int _numericId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }

    return hash;
  }
}
