// This is a generated file - do not edit.
//
// Generated from ferret/wake/v1/wake.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../v1/wake.pb.dart' as $0;
import 'wake.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'wake.pbenum.dart';

/// Asks a device that is on to send the magic packet for another of the
/// user's devices, for when the asking one can't reach that network itself
/// (an iPhone may not broadcast, a phone may be on mobile data). Expects a
/// `WakeReply`. The receiver acts only for a device it is paired with too.
class WakeRequest extends $pb.GeneratedMessage {
  factory WakeRequest({
    $core.String? deviceId,
    $0.WakeInfo? info,
    $core.String? lastAddress,
  }) {
    final result = WakeRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (info != null) result.info = info;
    if (lastAddress != null) result.lastAddress = lastAddress;
    return result;
  }

  WakeRequest._();

  factory WakeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeRequest()..mergeFromBuffer(data, registry);
  factory WakeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WakeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.wake.v1'),
      createEmptyInstance: WakeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aOM<$0.WakeInfo>(2, _omitFieldNames ? '' : 'info',
        subBuilder: $0.WakeInfo.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'lastAddress')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeRequest copyWith(void Function(WakeRequest) updates) =>
      super.copyWith((message) => updates(message as WakeRequest))
          as WakeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WakeRequest() / WakeRequest.new instead')
  static WakeRequest create() => WakeRequest._();
  static $pb.GeneratedMessage $_createMessage() => WakeRequest._();
  @$core.override
  WakeRequest createEmptyInstance() => WakeRequest._();
  @$core.pragma('dart2js:noInline')
  static WakeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WakeRequest>(
          WakeRequest.$_createMessage);
  static WakeRequest? _defaultInstance;

  /// The device to wake.
  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// What the asking device knows about how to wake it. The receiver uses
  /// its own copy first.
  @$pb.TagNumber(2)
  $0.WakeInfo get info => $_getN(1);
  @$pb.TagNumber(2)
  set info($0.WakeInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.WakeInfo ensureInfo() => $_ensure(1);

  /// The address the asking device last reached it at, such as
  /// "192.168.1.20".
  @$pb.TagNumber(3)
  $core.String get lastAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set lastAddress($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastAddress() => $_clearField(3);
}

/// What came of a `WakeRequest`.
class WakeReply extends $pb.GeneratedMessage {
  factory WakeReply({
    WakeResult? result,
  }) {
    final result$ = WakeReply._();
    if (result != null) result$.result = result;
    return result$;
  }

  WakeReply._();

  factory WakeReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeReply()..mergeFromBuffer(data, registry);
  factory WakeReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WakeReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.wake.v1'),
      createEmptyInstance: WakeReply.$_createMessage)
    ..aE<WakeResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: WakeResult.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeReply copyWith(void Function(WakeReply) updates) =>
      super.copyWith((message) => updates(message as WakeReply)) as WakeReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WakeReply() / WakeReply.new instead')
  static WakeReply create() => WakeReply._();
  static $pb.GeneratedMessage $_createMessage() => WakeReply._();
  @$core.override
  WakeReply createEmptyInstance() => WakeReply._();
  @$core.pragma('dart2js:noInline')
  static WakeReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WakeReply>(WakeReply.$_createMessage);
  static WakeReply? _defaultInstance;

  @$pb.TagNumber(1)
  WakeResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(WakeResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
