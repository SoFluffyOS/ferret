import 'dart:async';

import 'package:clipboard/models/models.dart';
import 'package:clipboard/services/services.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/clipboard.dart';
import 'package:protocol/protocol.dart';

/// Copy on one device, paste on another. Watches this device's clipboard,
/// pushes new clips to connected devices, and puts clips that arrive on the
/// clipboard here. Content is never logged and history stays in memory.
class ClipboardFeature extends Feature {
  ClipboardFeature({
    ClipboardPlatform Function()? clipboard,
    DateTime Function()? clock,
    ClipCodec? codec,
    PowerCapabilities Function()? power,
  }) : _createClipboard = clipboard ?? ClipboardPlatform.current,
       _createPower = power ?? PowerCapabilities.new,
       _clock = clock ?? DateTime.now,
       _codec = codec ?? ClipCodec();

  static const featureId = 'clipboard';
  static const historyLimit = 20;

  /// Flags in [FeatureSupport]: this device takes clips, sends them on its
  /// own, and takes images.
  static const receiveFlag = 'receive';
  static const sendFlag = 'send';
  static const imagesFlag = 'images';

  final ClipboardPlatform Function() _createClipboard;
  final DateTime Function() _clock;

  /// Ends "Waiting for a device" in Activity once the copy is too old to
  /// send.
  Timer? _waitTimer;
  final ClipCodec _codec;
  final PowerCapabilities Function() _createPower;

  /// Made on first use, once the app's platform channels are up.
  late final PowerCapabilities _power = _createPower();
  final ClipHistory _history = ClipHistory(limit: historyLimit);
  final RecentIds _seen = RecentIds();
  final StreamController<void> _changes = .broadcast();
  late final StreamController<ClipCopy> _copies = .broadcast(
    onListen: () => unawaited(_updateWatching()),
    onCancel: () => unawaited(_updateWatching()),
  );
  final Map<String, Timer> _expiryTimers = {};

  ClipboardPlatform? _clipboard;
  StreamSubscription<void>? _clipboardChanges;
  StreamSubscription<String>? _settingsChanges;
  StreamSubscription<PowerClip>? _backgroundClips;
  StreamSubscription<PowerTier>? _tierChanges;
  _LocalClip? _latestLocal;

  /// Fingerprint of what this device's clipboard holds as far as Ferret
  /// knows: the last clip read here or written here. Drops echoes.
  String? _currentHash;
  bool _reading = false;
  bool _readAgain = false;

  /// Set while [putOnClipboard] writes, so the change it causes is read
  /// only once its hash is known.
  Future<void>? _putting;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [
    receiveFlag,
    if (settings.autoSend) sendFlag,
    if (settings.syncImages) imagesFlag,
  ];

  ClipboardSettings get settings => ClipboardSettings(host.settings);

  /// How freely this platform lets Ferret read the clipboard. Until the
  /// feature starts, assumes a desktop.
  ClipboardAccess get access => _clipboard?.access ?? .always;

  /// Whether an Android power-up (Shizuku or root) is on, so copies made in
  /// other apps can be read while Ferret is in the background.
  bool get canSendInBackground =>
      access == .foreground && _power.activeTier.readsClipboardInBackground;

  /// Whether copies made in other apps go out on their own right now: the
  /// power-up is on and the user asked for it.
  bool get sendsInBackground =>
      canSendInBackground && settings.autoSend && settings.backgroundSend;

  /// Newest first, at most [historyLimit].
  List<ClipEntry> get history => _history.entries;

  ClipEntry? get latest => _history.latest;

  /// Fires when the history or the settings change.
  Stream<void> get changes => _changes.stream;

  /// Each new copy the clipboard here takes, copied here or arrived from
  /// another device, never a private one: for keeping, such as on the
  /// shelf. While someone listens, copies made here are noticed even when
  /// they aren't sent on their own.
  Stream<ClipCopy> get copies => _copies.stream;

  @override
  Future<void> onStart() async {
    final clipboard = _createClipboard();
    _clipboard = clipboard;
    _settingsChanges = settings.changes.listen(_onSettingChanged);
    _tierChanges = _power.tierChanges.listen((_) => _onTierChanged());

    if (clipboard.access.watchesOtherApps) {
      final current = await _read();
      if (current != null) {
        _currentHash = ClipCodec.hashOf(current);
      }
    }

    await _updateWatching();
  }

  @override
  Future<void> stop() async {
    await _settingsChanges?.cancel();
    _settingsChanges = null;
    await _tierChanges?.cancel();
    _tierChanges = null;
    await _stopBackgroundWatching();
    await _stopWatching();
    _waitTimer?.cancel();
    for (final timer in _expiryTimers.values) {
      timer.cancel();
    }

    _expiryTimers.clear();
  }

  /// Whether a connected device syncs its clipboard with this one.
  bool get hasPeers =>
      host.sessions.any((session) => session.supports(featureId));

  @override
  void onSessionClosed(Session session) => _changes.add(null);

  @override
  void onSessionOpened(Session session) {
    _changes.add(null);

    final latest = _latestLocal;
    if (latest == null || latest.item.sensitive) {
      return;
    }

    final age = _clock().difference(latest.at);
    if (age > settings.expiry ||
        latest.reached.contains(session.remoteDeviceId)) {
      return;
    }

    if (!_accepts(session, latest.item)) {
      return;
    }

    unawaited(
      _push(latest.item, [session]).then((reached) {
        latest.reached.addAll(reached.map((s) => s.remoteDeviceId));
        if (reached.isEmpty) {
          return;
        }

        _deliveredLater(latest.item.id, session);
      }),
    );
  }

  /// Whether [entry] was copied here while no device was connected, and
  /// still goes to the first one that connects within the expiry.
  bool isWaiting(ClipEntry entry) {
    if (entry.direction != .sent || entry.skip != .noDevices) {
      return false;
    }

    final latest = _latestLocal;
    if (latest == null || latest.item.id != entry.id) {
      return false;
    }

    return _clock().difference(latest.at) <= settings.expiry;
  }

  /// Activity says where a clip that waited went, once it went.
  void _deliveredLater(String id, Session session) {
    final changed = _history.update(id, (entry) {
      if (entry.deviceIds.contains(session.remoteDeviceId)) {
        return entry;
      }

      final waited = entry.skip == .noDevices || entry.deliveredLater;
      return entry.copyWith(
        skip: switch (entry.skip) {
          .noDevices => ClipSkip.none,
          _ => entry.skip,
        },
        deviceNames: [...entry.deviceNames, _nameOf(session)],
        deviceIds: [...entry.deviceIds, session.remoteDeviceId],
        deliveredLater: waited,
      );
    });
    if (changed) {
      _changes.add(null);
    }
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    final push = payloadOf(envelope, ClipPush.new);
    if (push == null) {
      return null;
    }

    await _receive(session, push.item);
    return null;
  }

  /// Reads this device's clipboard and sends it, to [toDeviceId] only when
  /// given. Sends even when it was synced already, since someone asked.
  Future<ClipSendResult> sendClipboard({String? toDeviceId}) async {
    final content = await _read() ?? await _readInBackground();
    if (content == null) {
      return .nothingToSend;
    }

    return _share(content, userAsked: true, toDeviceId: toDeviceId);
  }

  /// Sends [text], such as what the Android tile read from the clipboard
  /// or words dragged onto a device, to [toDeviceId] or every device.
  Future<ClipSendResult> sendText(String text, {String? toDeviceId}) async {
    if (text.isEmpty) {
      return .nothingToSend;
    }

    return _share(.text(text), userAsked: true, toDeviceId: toDeviceId);
  }

  /// Puts [entry] back on this device's clipboard. False when its content is
  /// gone or the write failed.
  Future<bool> copyToClipboard(ClipEntry entry) async {
    final clipboard = _clipboard;
    final content = ClipCodec.contentOf(entry.item);
    if (clipboard == null || content == null || !entry.hasContent) {
      return false;
    }

    try {
      await clipboard.write(content);
    } on Object catch (error) {
      printWarning('Could not copy a clip from history', error);
      return false;
    }

    _currentHash = ClipCodec.hashOf(content);
    _history.update(entry.id, (old) => old.copyWith(onClipboard: true));
    _changes.add(null);
    return true;
  }

  /// Puts [content] on this device's clipboard for another feature, such as
  /// a photo a phone just took for this computer. It came from a paired
  /// device already, so it isn't sent back out as a new clip. False when
  /// the write failed.
  Future<bool> putOnClipboard(ClipboardContent content) async {
    final clipboard = _clipboard;
    if (clipboard == null) {
      return false;
    }

    final putting = Completer<void>();
    _putting = putting.future;
    try {
      return await _put(clipboard, content);
    } finally {
      putting.complete();
      _putting = null;
    }
  }

  Future<bool> _put(
    ClipboardPlatform clipboard,
    ClipboardContent content,
  ) async {
    try {
      await clipboard.write(content);
    } on Object catch (error) {
      printWarning('Could not put content on the clipboard', error);
      return false;
    }

    _currentHash = ClipCodec.hashOf(content);
    // Some clipboards keep a converted copy, such as a JPEG as PNG on
    // Linux: what reads back must not go out again either.
    final stored = switch (clipboard.access) {
      .always || .whileFocused => await _read(),
      _ => null,
    };
    if (stored != null) {
      _currentHash = ClipCodec.hashOf(stored);
    }

    return true;
  }

  void clearHistory() {
    for (final timer in _expiryTimers.values) {
      timer.cancel();
    }

    _expiryTimers.clear();
    _history.clear();
    _changes.add(null);
  }

  void _onSettingChanged(String key) {
    if (key == ClipboardSettings.autoSendKey ||
        key == ClipboardSettings.backgroundSendKey) {
      unawaited(_updateWatching());
    }

    _changes.add(null);
  }

  void _onTierChanged() {
    unawaited(_updateWatching());
    _changes.add(null);
  }

  Future<void> _updateWatching() async {
    await _updateBackgroundWatching();
    await _updateForegroundWatching();
  }

  /// Listening is what starts the power-up's watcher, so there is no
  /// listener, and no watcher, unless the user turned this on.
  Future<void> _updateBackgroundWatching() async {
    if (!sendsInBackground) {
      await _stopBackgroundWatching();
      return;
    }

    _backgroundClips ??= _power.clipboardChanges.listen(_onBackgroundClip);
  }

  Future<void> _stopBackgroundWatching() async {
    final subscription = _backgroundClips;
    _backgroundClips = null;
    await subscription?.cancel();
  }

  /// A copy made in another app, read by the power-up. It goes through the
  /// same rules as any other copy: dedupe, private items, size.
  void _onBackgroundClip(PowerClip clip) {
    if (!sendsInBackground || clip.text.isEmpty) {
      return;
    }

    unawaited(
      _share(.text(clip.text, sensitive: clip.sensitive), userAsked: false),
    );
  }

  /// What the power-up reads when Android won't let the app itself, such as
  /// for "Send clipboard" tapped in the notification. Null unless the user
  /// turned background sending on.
  Future<ClipboardContent?> _readInBackground() async {
    if (!canSendInBackground || !settings.backgroundSend) {
      return null;
    }

    final clip = await _power.readClipboard();
    if (clip == null || clip.text.isEmpty) {
      return null;
    }

    return .text(clip.text, sensitive: clip.sensitive);
  }

  Future<void> _updateForegroundWatching() async {
    final clipboard = _clipboard;
    if (clipboard == null) {
      return;
    }

    final shouldWatch =
        (settings.autoSend || _copies.hasListener) &&
        clipboard.access != .onRequest;
    if (!shouldWatch) {
      await _stopWatching();
      return;
    }

    if (_clipboardChanges != null) {
      return;
    }

    final accessBefore = clipboard.access;
    _clipboardChanges = clipboard.changes.listen(
      (_) => unawaited(_onLocalChange()),
    );
    try {
      await clipboard.startWatching();
    } on Object catch (error) {
      printWarning('Could not watch the clipboard', error);
    }

    if (clipboard.access != accessBefore) {
      _changes.add(null);
    }
  }

  Future<void> _stopWatching() async {
    final subscription = _clipboardChanges;
    if (subscription == null) {
      return;
    }

    _clipboardChanges = null;
    await subscription.cancel();
    try {
      await _clipboard?.stopWatching();
    } on Object catch (error) {
      printWarning('Could not stop watching the clipboard', error);
    }
  }

  /// Change events can come in bursts; read once, and once more if another
  /// event arrived meanwhile.
  Future<void> _onLocalChange() async {
    if (_reading) {
      _readAgain = true;
      return;
    }

    if (_putting case final putting?) {
      await putting;
    }

    _reading = true;
    try {
      do {
        _readAgain = false;
        final content = await _read();
        if (content != null) {
          await _onLocalContent(content);
        }
      } while (_readAgain);
    } finally {
      _reading = false;
    }
  }

  /// A copy made here: sent when copies go out on their own, otherwise
  /// only noted for [copies].
  Future<void> _onLocalContent(ClipboardContent content) async {
    if (settings.autoSend) {
      await _share(content, userAsked: false);
      return;
    }

    final hash = ClipCodec.hashOf(content);
    if (hash == _currentHash) {
      return;
    }

    _currentHash = hash;
    _noteCopy(content);
  }

  void _noteCopy(ClipboardContent content, {String? fromDeviceId}) {
    if (content.sensitive || !_copies.hasListener) {
      return;
    }

    _copies.add(
      ClipCopy(content: content, at: _clock(), fromDeviceId: fromDeviceId),
    );
  }

  Future<ClipboardContent?> _read() async {
    try {
      return await _clipboard?.read();
    } on Object catch (error) {
      printWarning('Could not read the clipboard', error);
      return null;
    }
  }

  Future<ClipSendResult> _share(
    ClipboardContent content, {
    required bool userAsked,
    String? toDeviceId,
  }) async {
    final hash = ClipCodec.hashOf(content);
    if (!userAsked && hash == _currentHash) {
      return .duplicate;
    }

    _currentHash = hash;
    if (!userAsked) {
      _noteCopy(content);
    }

    final at = _clock();
    final item = _codec.itemFor(
      content,
      sourceDeviceId: host.identity.deviceId,
      at: at,
    );
    _seen.add(item.id);

    final skip = _skipFor(content);
    if (skip != .none) {
      _record(
        ClipEntry(item: item, direction: .sent, at: at, skip: skip),
      );
      return switch (skip) {
        .sensitive => ClipSendResult.sensitive,
        .imagesOff => ClipSendResult.imagesOff,
        _ => ClipSendResult.tooLarge,
      };
    }

    final targets = [
      for (final session in host.sessions)
        if ((toDeviceId == null || session.remoteDeviceId == toDeviceId) &&
            _accepts(session, item))
          session,
    ];
    final reached = await _push(item, targets);
    _latestLocal = _LocalClip(item, at, {
      for (final session in reached) session.remoteDeviceId,
    });

    _record(
      ClipEntry(
        item: item,
        direction: .sent,
        at: at,
        deviceNames: [for (final session in reached) _nameOf(session)],
        deviceIds: [for (final session in reached) session.remoteDeviceId],
        skip: switch (reached.isEmpty) {
          true => .noDevices,
          false => .none,
        },
      ),
    );

    if (targets.isEmpty) {
      _waitTimer?.cancel();
      _waitTimer = Timer(settings.expiry, () => _changes.add(null));
      return .noDevices;
    }

    if (reached.isEmpty) {
      return .failed;
    }

    return .sent;
  }

  Future<void> _receive(Session session, ClipItem item) async {
    if (item.id.isEmpty || !_seen.add(item.id)) {
      return;
    }

    if (item.sourceDeviceId == host.identity.deviceId) {
      return;
    }

    final content = ClipCodec.contentOf(item);
    if (content == null) {
      return;
    }

    final hash = ClipCodec.hashOf(content);
    if (hash == _currentHash) {
      return;
    }

    _noteCopy(content, fromDeviceId: session.remoteDeviceId);
    final entry = ClipEntry(
      item: item,
      direction: .received,
      at: _clock(),
      deviceNames: [_nameOf(session)],
      deviceIds: [session.remoteDeviceId],
      skip: _skipFor(content),
    );
    if (entry.skip != .none || !settings.autoReceive) {
      _record(entry);
      return;
    }

    try {
      await _clipboard?.write(content);
    } on Object catch (error) {
      printWarning('Could not put a received clip on the clipboard', error);
      _record(entry.copyWith(skip: .writeFailed));
      return;
    }

    _currentHash = hash;
    _record(entry.copyWith(onClipboard: true));
  }

  ClipSkip _skipFor(ClipboardContent content) {
    final settings = this.settings;
    if (content.sensitive && !settings.syncSensitive) {
      return .sensitive;
    }

    if (content.isImage && !settings.syncImages) {
      return .imagesOff;
    }

    final limit = switch (content.isImage) {
      true => settings.maxImageBytes,
      false => ClipboardSettings.maxTextBytes,
    };
    if (ClipCodec.sizeOf(content) > limit) {
      return .tooLarge;
    }

    return .none;
  }

  bool _accepts(Session session, ClipItem item) {
    final support = session.remoteFeature(featureId);
    if (support == null) {
      return false;
    }

    return item.kind != ClipKind.CLIP_KIND_IMAGE ||
        support.flags.contains(imagesFlag);
  }

  Future<List<Session>> _push(ClipItem item, List<Session> sessions) async {
    final push = ClipPush(
      item: item,
      expiresInMs: Int64(settings.expiry.inMilliseconds),
    );
    final reached = <Session>[];
    for (final session in sessions) {
      try {
        await session.send(featureId, push);
        reached.add(session);
      } on Object catch (error) {
        printWarning(
          'Clipboard item to ${session.remoteDeviceId} failed',
          error,
        );
      }
    }

    return reached;
  }

  void _record(ClipEntry entry) {
    final kept = switch (entry.skip) {
      .sensitive => entry.redact(),
      _ => entry,
    };
    _history.add(kept);
    _scheduleExpiry(kept);
    _changes.add(null);
  }

  /// Private clips leave memory after the expiry, like Apple's clipboard.
  void _scheduleExpiry(ClipEntry entry) {
    if (!entry.isSensitive || entry.redacted) {
      return;
    }

    _expiryTimers[entry.id] = Timer(settings.expiry, () {
      _expiryTimers.remove(entry.id);
      if (_history.update(entry.id, (old) => old.redact())) {
        _changes.add(null);
      }
    });
  }

  String _nameOf(Session session) => host.displayNameOf(session.remoteDeviceId);
}

/// The last clip copied here, and the devices that got it.
class _LocalClip {
  _LocalClip(this.item, this.at, this.reached);

  final ClipItem item;
  final DateTime at;
  final Set<String> reached;
}
