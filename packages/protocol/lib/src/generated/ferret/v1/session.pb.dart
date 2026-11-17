// This is a generated file - do not edit.
//
// Generated from ferret/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'device.pb.dart' as $0;
import 'session.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'session.pbenum.dart';

/// First envelope each side sends on a trusted session (feature "session").
class Hello extends $pb.GeneratedMessage {
  factory Hello({
    $0.DeviceInfo? device,
    $core.Iterable<$0.FeatureSupport>? features,
    $core.int? listenPort,
  }) {
    final result = Hello._();
    if (device != null) result.device = device;
    if (features != null) result.features.addAll(features);
    if (listenPort != null) result.listenPort = listenPort;
    return result;
  }

  Hello._();

  factory Hello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Hello()..mergeFromBuffer(data, registry);
  factory Hello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Hello()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Hello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Hello.$_createMessage)
    ..aOM<$0.DeviceInfo>(1, _omitFieldNames ? '' : 'device',
        subBuilder: $0.DeviceInfo.$_createMessage)
    ..pPM<$0.FeatureSupport>(2, _omitFieldNames ? '' : 'features',
        subBuilder: $0.FeatureSupport.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'listenPort', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello copyWith(void Function(Hello) updates) =>
      super.copyWith((message) => updates(message as Hello)) as Hello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Hello() / Hello.new instead')
  static Hello create() => Hello._();
  static $pb.GeneratedMessage $_createMessage() => Hello._();
  @$core.override
  Hello createEmptyInstance() => Hello._();
  @$core.pragma('dart2js:noInline')
  static Hello getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Hello>(Hello.$_createMessage);
  static Hello? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DeviceInfo get device => $_getN(0);
  @$pb.TagNumber(1)
  set device($0.DeviceInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.DeviceInfo ensureDevice() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$0.FeatureSupport> get features => $_getList(1);

  /// TCP port this device accepts connections on, for reconnecting later.
  @$pb.TagNumber(3)
  $core.int get listenPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set listenPort($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasListenPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearListenPort() => $_clearField(3);
}

/// Keeps a session alive and measures round trips (feature "session").
class Ping extends $pb.GeneratedMessage {
  factory Ping({
    $fixnum.Int64? sentAtMs,
  }) {
    final result = Ping._();
    if (sentAtMs != null) result.sentAtMs = sentAtMs;
    return result;
  }

  Ping._();

  factory Ping.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ping()..mergeFromBuffer(data, registry);
  factory Ping.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ping()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ping',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Ping.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sentAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ping clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ping copyWith(void Function(Ping) updates) =>
      super.copyWith((message) => updates(message as Ping)) as Ping;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ping() / Ping.new instead')
  static Ping create() => Ping._();
  static $pb.GeneratedMessage $_createMessage() => Ping._();
  @$core.override
  Ping createEmptyInstance() => Ping._();
  @$core.pragma('dart2js:noInline')
  static Ping getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ping>(Ping.$_createMessage);
  static Ping? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sentAtMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sentAtMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSentAtMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSentAtMs() => $_clearField(1);
}

class Pong extends $pb.GeneratedMessage {
  factory Pong({
    $fixnum.Int64? pingSentAtMs,
  }) {
    final result = Pong._();
    if (pingSentAtMs != null) result.pingSentAtMs = pingSentAtMs;
    return result;
  }

  Pong._();

  factory Pong.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Pong()..mergeFromBuffer(data, registry);
  factory Pong.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Pong()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Pong',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Pong.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'pingSentAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pong clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pong copyWith(void Function(Pong) updates) =>
      super.copyWith((message) => updates(message as Pong)) as Pong;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Pong() / Pong.new instead')
  static Pong create() => Pong._();
  static $pb.GeneratedMessage $_createMessage() => Pong._();
  @$core.override
  Pong createEmptyInstance() => Pong._();
  @$core.pragma('dart2js:noInline')
  static Pong getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Pong>(Pong.$_createMessage);
  static Pong? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get pingSentAtMs => $_getI64(0);
  @$pb.TagNumber(1)
  set pingSentAtMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPingSentAtMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPingSentAtMs() => $_clearField(1);
}

/// Says the user is active on this device right now, so others know where to
/// show suggestions (feature "session").
class Presence extends $pb.GeneratedMessage {
  factory Presence({
    $core.bool? userActive,
    $core.bool? screenOn,
    $core.int? batteryPercent,
    $core.bool? charging,
  }) {
    final result = Presence._();
    if (userActive != null) result.userActive = userActive;
    if (screenOn != null) result.screenOn = screenOn;
    if (batteryPercent != null) result.batteryPercent = batteryPercent;
    if (charging != null) result.charging = charging;
    return result;
  }

  Presence._();

  factory Presence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Presence()..mergeFromBuffer(data, registry);
  factory Presence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Presence()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Presence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Presence.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'userActive')
    ..aOB(2, _omitFieldNames ? '' : 'screenOn')
    ..aI(3, _omitFieldNames ? '' : 'batteryPercent')
    ..aOB(4, _omitFieldNames ? '' : 'charging')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Presence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Presence copyWith(void Function(Presence) updates) =>
      super.copyWith((message) => updates(message as Presence)) as Presence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Presence() / Presence.new instead')
  static Presence create() => Presence._();
  static $pb.GeneratedMessage $_createMessage() => Presence._();
  @$core.override
  Presence createEmptyInstance() => Presence._();
  @$core.pragma('dart2js:noInline')
  static Presence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Presence>(Presence.$_createMessage);
  static Presence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get userActive => $_getBF(0);
  @$pb.TagNumber(1)
  set userActive($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserActive() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserActive() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get screenOn => $_getBF(1);
  @$pb.TagNumber(2)
  set screenOn($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScreenOn() => $_has(1);
  @$pb.TagNumber(2)
  void clearScreenOn() => $_clearField(2);

  /// Battery level 0-100, or -1 when unknown or plugged desktop.
  @$pb.TagNumber(3)
  $core.int get batteryPercent => $_getIZ(2);
  @$pb.TagNumber(3)
  set batteryPercent($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBatteryPercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatteryPercent() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get charging => $_getBF(3);
  @$pb.TagNumber(4)
  set charging($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCharging() => $_has(3);
  @$pb.TagNumber(4)
  void clearCharging() => $_clearField(4);
}

/// Sent before a side closes on purpose, so the other one doesn't reconnect.
class Goodbye extends $pb.GeneratedMessage {
  factory Goodbye({
    GoodbyeReason? reason,
  }) {
    final result = Goodbye._();
    if (reason != null) result.reason = reason;
    return result;
  }

  Goodbye._();

  factory Goodbye.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Goodbye()..mergeFromBuffer(data, registry);
  factory Goodbye.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Goodbye()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Goodbye',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Goodbye.$_createMessage)
    ..aE<GoodbyeReason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: GoodbyeReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Goodbye clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Goodbye copyWith(void Function(Goodbye) updates) =>
      super.copyWith((message) => updates(message as Goodbye)) as Goodbye;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Goodbye() / Goodbye.new instead')
  static Goodbye create() => Goodbye._();
  static $pb.GeneratedMessage $_createMessage() => Goodbye._();
  @$core.override
  Goodbye createEmptyInstance() => Goodbye._();
  @$core.pragma('dart2js:noInline')
  static Goodbye getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Goodbye>(Goodbye.$_createMessage);
  static Goodbye? _defaultInstance;

  @$pb.TagNumber(1)
  GoodbyeReason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(GoodbyeReason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
