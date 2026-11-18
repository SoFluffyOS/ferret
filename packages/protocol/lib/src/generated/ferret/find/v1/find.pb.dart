// This is a generated file - do not edit.
//
// Generated from ferret/find/v1/find.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'find.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'find.pbenum.dart';

/// Asks the receiver to ring so someone can find it. Expects a `RingStatus`
/// reply. Asking a device that already rings restarts its countdown.
class RingRequest extends $pb.GeneratedMessage {
  factory RingRequest({
    $core.int? durationSeconds,
    $core.bool? overrideSilent,
  }) {
    final result = RingRequest._();
    if (durationSeconds != null) result.durationSeconds = durationSeconds;
    if (overrideSilent != null) result.overrideSilent = overrideSilent;
    return result;
  }

  RingRequest._();

  factory RingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RingRequest()..mergeFromBuffer(data, registry);
  factory RingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.find.v1'),
      createEmptyInstance: RingRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'durationSeconds',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'overrideSilent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RingRequest copyWith(void Function(RingRequest) updates) =>
      super.copyWith((message) => updates(message as RingRequest))
          as RingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RingRequest() / RingRequest.new instead')
  static RingRequest create() => RingRequest._();
  static $pb.GeneratedMessage $_createMessage() => RingRequest._();
  @$core.override
  RingRequest createEmptyInstance() => RingRequest._();
  @$core.pragma('dart2js:noInline')
  static RingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RingRequest>(
          RingRequest.$_createMessage);
  static RingRequest? _defaultInstance;

  /// How long to ring before stopping on its own. 0 means the receiver's
  /// default; receivers cap long values.
  @$pb.TagNumber(1)
  $core.int get durationSeconds => $_getIZ(0);
  @$pb.TagNumber(1)
  set durationSeconds($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDurationSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearDurationSeconds() => $_clearField(1);

  /// Ring even when the receiver is on silent or Do Not Disturb, if its owner
  /// allowed that on the receiver.
  @$pb.TagNumber(2)
  $core.bool get overrideSilent => $_getBF(1);
  @$pb.TagNumber(2)
  set overrideSilent($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOverrideSilent() => $_has(1);
  @$pb.TagNumber(2)
  void clearOverrideSilent() => $_clearField(2);
}

/// Asks the receiver to stop ringing. Expects a `RingStatus` reply.
class StopRingRequest extends $pb.GeneratedMessage {
  factory StopRingRequest() => StopRingRequest._();

  StopRingRequest._();

  factory StopRingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopRingRequest()..mergeFromBuffer(data, registry);
  factory StopRingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopRingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopRingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.find.v1'),
      createEmptyInstance: StopRingRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopRingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopRingRequest copyWith(void Function(StopRingRequest) updates) =>
      super.copyWith((message) => updates(message as StopRingRequest))
          as StopRingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StopRingRequest() / StopRingRequest.new instead')
  static StopRingRequest create() => StopRingRequest._();
  static $pb.GeneratedMessage $_createMessage() => StopRingRequest._();
  @$core.override
  StopRingRequest createEmptyInstance() => StopRingRequest._();
  @$core.pragma('dart2js:noInline')
  static StopRingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StopRingRequest>(
          StopRingRequest.$_createMessage);
  static StopRingRequest? _defaultInstance;
}

/// Where a ring stands. The reply to `RingRequest` and `StopRingRequest`, and
/// sent without expecting a reply to each device that asked for the ring when
/// it stops on the ringing device.
class RingStatus extends $pb.GeneratedMessage {
  factory RingStatus({
    RingState? state,
    StopReason? reason,
    $core.int? remainingMs,
    $core.bool? muted,
  }) {
    final result = RingStatus._();
    if (state != null) result.state = state;
    if (reason != null) result.reason = reason;
    if (remainingMs != null) result.remainingMs = remainingMs;
    if (muted != null) result.muted = muted;
    return result;
  }

  RingStatus._();

  factory RingStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RingStatus()..mergeFromBuffer(data, registry);
  factory RingStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RingStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RingStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.find.v1'),
      createEmptyInstance: RingStatus.$_createMessage)
    ..aE<RingState>(1, _omitFieldNames ? '' : 'state',
        enumValues: RingState.values)
    ..aE<StopReason>(2, _omitFieldNames ? '' : 'reason',
        enumValues: StopReason.values)
    ..aI(3, _omitFieldNames ? '' : 'remainingMs',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'muted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RingStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RingStatus copyWith(void Function(RingStatus) updates) =>
      super.copyWith((message) => updates(message as RingStatus)) as RingStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RingStatus() / RingStatus.new instead')
  static RingStatus create() => RingStatus._();
  static $pb.GeneratedMessage $_createMessage() => RingStatus._();
  @$core.override
  RingStatus createEmptyInstance() => RingStatus._();
  @$core.pragma('dart2js:noInline')
  static RingStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RingStatus>(RingStatus.$_createMessage);
  static RingStatus? _defaultInstance;

  @$pb.TagNumber(1)
  RingState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(RingState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Set when `state` is `RING_STATE_STOPPED`.
  @$pb.TagNumber(2)
  StopReason get reason => $_getN(1);
  @$pb.TagNumber(2)
  set reason(StopReason value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);

  /// Milliseconds left until the ring stops on its own, while ringing.
  @$pb.TagNumber(3)
  $core.int get remainingMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set remainingMs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRemainingMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemainingMs() => $_clearField(3);

  /// It rings, but without sound, because it is on silent or Do Not Disturb
  /// and may not override that. It still vibrates and shows a notice.
  @$pb.TagNumber(4)
  $core.bool get muted => $_getBF(3);
  @$pb.TagNumber(4)
  set muted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMuted() => $_has(3);
  @$pb.TagNumber(4)
  void clearMuted() => $_clearField(4);
}

/// Asks what the receiver can do when rung. Expects a `RingInfo` reply.
class GetRingInfo extends $pb.GeneratedMessage {
  factory GetRingInfo() => GetRingInfo._();

  GetRingInfo._();

  factory GetRingInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRingInfo()..mergeFromBuffer(data, registry);
  factory GetRingInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRingInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRingInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.find.v1'),
      createEmptyInstance: GetRingInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRingInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRingInfo copyWith(void Function(GetRingInfo) updates) =>
      super.copyWith((message) => updates(message as GetRingInfo))
          as GetRingInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRingInfo() / GetRingInfo.new instead')
  static GetRingInfo create() => GetRingInfo._();
  static $pb.GeneratedMessage $_createMessage() => GetRingInfo._();
  @$core.override
  GetRingInfo createEmptyInstance() => GetRingInfo._();
  @$core.pragma('dart2js:noInline')
  static GetRingInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRingInfo>(
          GetRingInfo.$_createMessage);
  static GetRingInfo? _defaultInstance;
}

/// What the receiver can do when rung. The reply to `GetRingInfo`, and sent
/// without expecting a reply when it changes, such as after a permission was
/// granted.
class RingInfo extends $pb.GeneratedMessage {
  factory RingInfo({
    $core.bool? ringing,
    $core.bool? ringsWhenSilent,
    $core.bool? needsAppOpen,
    $core.bool? needsPermission,
  }) {
    final result = RingInfo._();
    if (ringing != null) result.ringing = ringing;
    if (ringsWhenSilent != null) result.ringsWhenSilent = ringsWhenSilent;
    if (needsAppOpen != null) result.needsAppOpen = needsAppOpen;
    if (needsPermission != null) result.needsPermission = needsPermission;
    return result;
  }

  RingInfo._();

  factory RingInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RingInfo()..mergeFromBuffer(data, registry);
  factory RingInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RingInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RingInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.find.v1'),
      createEmptyInstance: RingInfo.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ringing')
    ..aOB(2, _omitFieldNames ? '' : 'ringsWhenSilent')
    ..aOB(3, _omitFieldNames ? '' : 'needsAppOpen')
    ..aOB(4, _omitFieldNames ? '' : 'needsPermission')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RingInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RingInfo copyWith(void Function(RingInfo) updates) =>
      super.copyWith((message) => updates(message as RingInfo)) as RingInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RingInfo() / RingInfo.new instead')
  static RingInfo create() => RingInfo._();
  static $pb.GeneratedMessage $_createMessage() => RingInfo._();
  @$core.override
  RingInfo createEmptyInstance() => RingInfo._();
  @$core.pragma('dart2js:noInline')
  static RingInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RingInfo>(RingInfo.$_createMessage);
  static RingInfo? _defaultInstance;

  /// It rings right now.
  @$pb.TagNumber(1)
  $core.bool get ringing => $_getBF(0);
  @$pb.TagNumber(1)
  set ringing($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRinging() => $_has(0);
  @$pb.TagNumber(1)
  void clearRinging() => $_clearField(1);

  /// It rings out loud even on silent or Do Not Disturb.
  @$pb.TagNumber(2)
  $core.bool get ringsWhenSilent => $_getBF(1);
  @$pb.TagNumber(2)
  set ringsWhenSilent($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRingsWhenSilent() => $_has(1);
  @$pb.TagNumber(2)
  void clearRingsWhenSilent() => $_clearField(2);

  /// It can only ring while Ferret is open on it, such as on iOS.
  @$pb.TagNumber(3)
  $core.bool get needsAppOpen => $_getBF(2);
  @$pb.TagNumber(3)
  set needsAppOpen($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNeedsAppOpen() => $_has(2);
  @$pb.TagNumber(3)
  void clearNeedsAppOpen() => $_clearField(3);

  /// Its owner turned ringing on silent on, but the system permission for it
  /// is missing.
  @$pb.TagNumber(4)
  $core.bool get needsPermission => $_getBF(3);
  @$pb.TagNumber(4)
  set needsPermission($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNeedsPermission() => $_has(3);
  @$pb.TagNumber(4)
  void clearNeedsPermission() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
