import 'package:core/core.dart';
import 'package:mirroring/models/mirror_record.dart';
import 'package:mirroring/models/quality_preset.dart';

/// Screen mirroring's settings, stored under `mirroring.*`.
class MirroringSettings {
  const MirroringSettings(this._store);

  static const enabledKey = 'mirroring.enabled';
  static const historyKey = 'mirroring.history';
  static const lookForCableKey = 'mirroring.look_for_cable';
  static const qualityKey = 'mirroring.quality';
  static const toolbarPinnedKey = 'mirroring.toolbar_pinned';
  static const cableToldKey = 'mirroring.cable_told';
  static const soundKey = 'mirroring.sound';
  static const soundVolumeKey = 'mirroring.sound_volume';
  static const sendSoundKey = 'mirroring.send_sound';
  static const controlAlwaysKey = 'mirroring.control_always';

  /// The one switch the cable and the receivers used to share. Only read,
  /// so a computer that had it on keeps both.
  static const moreWaysKey = 'mirroring.more_ways';
  static const receiverKeyPrefix = 'mirroring.receiver.';
  static const blockedDevicesKey = 'mirroring.blocked_devices';

  /// How many past times of mirroring the history keeps.
  static const historyLength = 20;

  final SettingsStore _store;

  /// Paired computers may ask to see this screen. On by default: Android
  /// still asks its owner every single time.
  bool get enabled => _store.get<bool>(enabledKey) ?? true;

  /// Paired computers the owner turned away for good: they can't even
  /// ask to see this screen.
  List<String> get blockedDevices => [
    for (final id in _store.get<List<Object?>>(blockedDevicesKey) ?? const [])
      if (id case final String deviceId) deviceId,
  ];

  bool isBlocked(String deviceId) => blockedDevices.contains(deviceId);

  /// Past times of mirroring on this device, newest first.
  List<MirrorRecord> get history => [
    for (final json in _store.get<List<Object?>>(historyKey) ?? const [])
      ?MirrorRecord.fromJson(json),
  ];

  /// This computer looks for Android phones with debugging on, plugged
  /// in or on the network. Off until the cable steps are first opened.
  bool get lookForCable => _store.get<bool>(lookForCableKey) ?? _hadMoreWays;

  Future<void> setLookForCable(bool value) =>
      _store.set(lookForCableKey, value);

  /// Whether the receiver [receiverId] listens for devices that send their
  /// screen here. Off until its owner flips the switch; [byDefault] only
  /// counts on a computer that had the old shared switch on.
  bool receiverOn(String receiverId, {required bool byDefault}) =>
      _store.get<bool>('$receiverKeyPrefix$receiverId') ??
      (_hadMoreWays && byDefault);

  Future<void> setReceiverOn(String receiverId, bool value) =>
      _store.set('$receiverKeyPrefix$receiverId', value);

  QualityPreset get quality => .named(_store.get<String>(qualityKey));

  Future<void> setQuality(QualityPreset preset) =>
      _store.set(qualityKey, preset.name);

  /// The toolbar stays under the picture instead of hiding over it.
  bool get toolbarPinned => _store.get<bool>(toolbarPinnedKey) ?? false;

  Future<void> setToolbarPinned(bool value) =>
      _store.set(toolbarPinnedKey, value);

  /// A shown screen's sound plays on this computer. On by default: over
  /// the cable it just works, and over Ferret the phone's owner decides
  /// whether sound is sent at all.
  bool get sound => _store.get<bool>(soundKey) ?? true;

  Future<void> setSound(bool value) => _store.set(soundKey, value);

  /// How loud a shown screen's sound plays here, from 0 to 1.
  double get soundVolume =>
      (_store.get<num>(soundVolumeKey) ?? 1).clamp(0, 1).toDouble();

  Future<void> setSoundVolume(double value) =>
      _store.set(soundVolumeKey, value.clamp(0, 1).toDouble());

  /// This phone sends what it plays along with its screen. Off until its
  /// owner turns it on, which is when Android asks for the permission.
  bool get sendSound => _store.get<bool>(sendSoundKey) ?? false;

  Future<void> setSendSound(bool value) => _store.set(sendSoundKey, value);

  /// The computers this phone's owner answered Always: they control it
  /// without asking while it shows them its screen.
  List<String> get controlAlways => [
    for (final id in _store.get<List<Object?>>(controlAlwaysKey) ?? const [])
      if (id case final String deviceId) deviceId,
  ];

  Future<void> setControlAlways(String deviceId, bool always) =>
      _store.set(controlAlwaysKey, [
        for (final id in controlAlways)
          if (id != deviceId) id,
        if (always) deviceId,
      ]);

  Future<void> clearControlAlways() =>
      _store.set(controlAlwaysKey, const <Object?>[]);

  /// The phones whose owner was told once that a cable doesn't ask.
  List<String> get cableTold => [
    for (final id in _store.get<List<Object?>>(cableToldKey) ?? const [])
      if (id case final String targetId) targetId,
  ];

  Future<void> addCableTold(String targetId) => _store.set(cableToldKey, [
    for (final id in cableTold)
      if (id != targetId) id,
    targetId,
  ]);

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

  Future<void> setBlocked(String deviceId, bool blocked) =>
      _store.set(blockedDevicesKey, [
        for (final id in blockedDevices)
          if (id != deviceId) id,
        if (blocked) deviceId,
      ]);

  Future<void> addRecord(MirrorRecord record) => _store.set(historyKey, [
    record.toJson(),
    for (final past in history.take(historyLength - 1)) past.toJson(),
  ]);

  Future<void> clearHistory() => _store.set(historyKey, const <Object?>[]);

  bool get _hadMoreWays => _store.get<bool>(moreWaysKey) ?? false;

  /// Fires with the key of each setting that changes.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('mirroring.'));
}
