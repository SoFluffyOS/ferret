import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:iphone/iphone.dart';

const iphoneDevice = BondedDevice(
  id: 'iphone-1',
  name: 'Zoé’s iPhone',
  connected: true,
);

/// Settings with the feature on and [iphoneDevice] picked.
Map<String, Object?> pairedSettings([Map<String, Object?>? more]) => {
  IphoneSettings.enabledKey: true,
  IphoneSettings.deviceIdKey: iphoneDevice.id,
  IphoneSettings.deviceNameKey: iphoneDevice.name,
  ...?more,
};

/// Just enough of the engine for the feature: its settings.
class FakeHost implements FeatureHost {
  FakeHost([Map<String, Object?>? settings])
    : settings = MemorySettingsStore(settings);

  @override
  final MemorySettingsStore settings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the notices a feature shows and cancels, and lets a test tap
/// them.
class RecordingNotifier implements LocalNotifier {
  final Map<String, LocalNotice> shown = {};
  final List<LocalNotice> history = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast(sync: true);

  void respond(String noticeId, {String? actionId}) =>
      _responses.add(NoticeResponse(noticeId: noticeId, actionId: actionId));

  @override
  Future<void> show(LocalNotice notice) async {
    shown[notice.id] = notice;
    history.add(notice);
  }

  @override
  Future<void> cancel(String id) async {
    shown.remove(id);
    cancelled.add(id);
  }

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}

/// A feature on a fake transport with a fake iPhone on the other end.
class Rig {
  Rig._(this.host, this.transport, this.iphone, this.feature);

  final FakeHost host;
  final FakeAppleTransport transport;
  final FakeIphone iphone;
  final IphoneFeature feature;

  /// Starts the feature. With [pairedSettings] it connects once queued
  /// futures ran ([settle], or a pump).
  static Future<Rig> start({
    Map<String, Object?>? settings,
    FakeAppleTransport? transport,
    DateTime Function()? clock,
    List<Duration>? retryDelays,
    Duration connectTimeout = const Duration(seconds: 25),
  }) async {
    final fake = transport ?? FakeAppleTransport(bonded: [iphoneDevice]);
    final host = FakeHost(settings);
    final feature = IphoneFeature(
      transport: () => fake,
      clock: clock,
      isSupported: true,
      retryDelays: retryDelays,
      connectTimeout: connectTimeout,
    );
    final rig = Rig._(host, fake, FakeIphone(fake), feature);
    await feature.start(host);
    return rig;
  }
}

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var turn = 0; turn < 10; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}
