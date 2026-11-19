// This is a generated file - do not edit.
//
// Generated from ferret/camera/v1/camera.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'camera.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'camera.pbenum.dart';

/// Asks the phone for a picture (a request, answered with CaptureReply right
/// away; the picture comes later with CaptureResult).
class CaptureRequest extends $pb.GeneratedMessage {
  factory CaptureRequest({
    $core.String? requestId,
    CaptureKind? kind,
  }) {
    final result = CaptureRequest._();
    if (requestId != null) result.requestId = requestId;
    if (kind != null) result.kind = kind;
    return result;
  }

  CaptureRequest._();

  factory CaptureRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureRequest()..mergeFromBuffer(data, registry);
  factory CaptureRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.camera.v1'),
      createEmptyInstance: CaptureRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aE<CaptureKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: CaptureKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureRequest copyWith(void Function(CaptureRequest) updates) =>
      super.copyWith((message) => updates(message as CaptureRequest))
          as CaptureRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CaptureRequest() / CaptureRequest.new instead')
  static CaptureRequest create() => CaptureRequest._();
  static $pb.GeneratedMessage $_createMessage() => CaptureRequest._();
  @$core.override
  CaptureRequest createEmptyInstance() => CaptureRequest._();
  @$core.pragma('dart2js:noInline')
  static CaptureRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CaptureRequest>(
          CaptureRequest.$_createMessage);
  static CaptureRequest? _defaultInstance;

  /// Chosen by the asking device; unique among its requests.
  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  CaptureKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(CaptureKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);
}

class CaptureReply extends $pb.GeneratedMessage {
  factory CaptureReply({
    $core.String? requestId,
    CaptureStatus? status,
  }) {
    final result = CaptureReply._();
    if (requestId != null) result.requestId = requestId;
    if (status != null) result.status = status;
    return result;
  }

  CaptureReply._();

  factory CaptureReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureReply()..mergeFromBuffer(data, registry);
  factory CaptureReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.camera.v1'),
      createEmptyInstance: CaptureReply.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aE<CaptureStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: CaptureStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureReply copyWith(void Function(CaptureReply) updates) =>
      super.copyWith((message) => updates(message as CaptureReply))
          as CaptureReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CaptureReply() / CaptureReply.new instead')
  static CaptureReply create() => CaptureReply._();
  static $pb.GeneratedMessage $_createMessage() => CaptureReply._();
  @$core.override
  CaptureReply createEmptyInstance() => CaptureReply._();
  @$core.pragma('dart2js:noInline')
  static CaptureReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CaptureReply>(
          CaptureReply.$_createMessage);
  static CaptureReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  /// ASKING when the phone shows the request, else why it can't.
  @$pb.TagNumber(2)
  CaptureStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(CaptureStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

/// How a request ended, sent by the phone. No reply.
class CaptureResult extends $pb.GeneratedMessage {
  factory CaptureResult({
    $core.String? requestId,
    CaptureStatus? status,
    $core.String? transferId,
    $core.String? mimeType,
  }) {
    final result = CaptureResult._();
    if (requestId != null) result.requestId = requestId;
    if (status != null) result.status = status;
    if (transferId != null) result.transferId = transferId;
    if (mimeType != null) result.mimeType = mimeType;
    return result;
  }

  CaptureResult._();

  factory CaptureResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureResult()..mergeFromBuffer(data, registry);
  factory CaptureResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.camera.v1'),
      createEmptyInstance: CaptureResult.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aE<CaptureStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: CaptureStatus.values)
    ..aOS(3, _omitFieldNames ? '' : 'transferId')
    ..aOS(4, _omitFieldNames ? '' : 'mimeType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureResult copyWith(void Function(CaptureResult) updates) =>
      super.copyWith((message) => updates(message as CaptureResult))
          as CaptureResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CaptureResult() / CaptureResult.new instead')
  static CaptureResult create() => CaptureResult._();
  static $pb.GeneratedMessage $_createMessage() => CaptureResult._();
  @$core.override
  CaptureResult createEmptyInstance() => CaptureResult._();
  @$core.pragma('dart2js:noInline')
  static CaptureResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CaptureResult>(
          CaptureResult.$_createMessage);
  static CaptureResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  CaptureStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(CaptureStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  /// The drop transfer carrying the picture, when status is TAKEN. The
  /// asking device accepts it on its own: it asked for it.
  @$pb.TagNumber(3)
  $core.String get transferId => $_getSZ(2);
  @$pb.TagNumber(3)
  set transferId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTransferId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTransferId() => $_clearField(3);

  /// Such as "image/jpeg" or "application/pdf".
  @$pb.TagNumber(4)
  $core.String get mimeType => $_getSZ(3);
  @$pb.TagNumber(4)
  set mimeType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMimeType() => $_has(3);
  @$pb.TagNumber(4)
  void clearMimeType() => $_clearField(4);
}

/// The asking device doesn't want the picture any more: the phone takes the
/// request away. A picture taken after this is thrown away. No reply.
class CaptureCancel extends $pb.GeneratedMessage {
  factory CaptureCancel({
    $core.String? requestId,
  }) {
    final result = CaptureCancel._();
    if (requestId != null) result.requestId = requestId;
    return result;
  }

  CaptureCancel._();

  factory CaptureCancel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureCancel()..mergeFromBuffer(data, registry);
  factory CaptureCancel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CaptureCancel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureCancel',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.camera.v1'),
      createEmptyInstance: CaptureCancel.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureCancel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureCancel copyWith(void Function(CaptureCancel) updates) =>
      super.copyWith((message) => updates(message as CaptureCancel))
          as CaptureCancel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CaptureCancel() / CaptureCancel.new instead')
  static CaptureCancel create() => CaptureCancel._();
  static $pb.GeneratedMessage $_createMessage() => CaptureCancel._();
  @$core.override
  CaptureCancel createEmptyInstance() => CaptureCancel._();
  @$core.pragma('dart2js:noInline')
  static CaptureCancel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CaptureCancel>(
          CaptureCancel.$_createMessage);
  static CaptureCancel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
