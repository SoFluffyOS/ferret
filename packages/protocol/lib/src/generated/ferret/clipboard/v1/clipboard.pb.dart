// This is a generated file - do not edit.
//
// Generated from ferret/clipboard/v1/clipboard.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'clipboard.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'clipboard.pbenum.dart';

/// One thing someone copied.
class ClipItem extends $pb.GeneratedMessage {
  factory ClipItem({
    $core.String? id,
    ClipKind? kind,
    $core.String? text,
    $core.List<$core.int>? image,
    $core.String? imageMime,
    $fixnum.Int64? createdAtMs,
    $core.String? sourceDeviceId,
    $core.bool? sensitive,
    $core.List<$core.int>? contentHash,
  }) {
    final result = ClipItem._();
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (text != null) result.text = text;
    if (image != null) result.image = image;
    if (imageMime != null) result.imageMime = imageMime;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (sourceDeviceId != null) result.sourceDeviceId = sourceDeviceId;
    if (sensitive != null) result.sensitive = sensitive;
    if (contentHash != null) result.contentHash = contentHash;
    return result;
  }

  ClipItem._();

  factory ClipItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClipItem()..mergeFromBuffer(data, registry);
  factory ClipItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClipItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClipItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.clipboard.v1'),
      createEmptyInstance: ClipItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ClipKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: ClipKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'image', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'imageMime')
    ..aInt64(6, _omitFieldNames ? '' : 'createdAtMs')
    ..aOS(7, _omitFieldNames ? '' : 'sourceDeviceId')
    ..aOB(8, _omitFieldNames ? '' : 'sensitive')
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'contentHash', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClipItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClipItem copyWith(void Function(ClipItem) updates) =>
      super.copyWith((message) => updates(message as ClipItem)) as ClipItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClipItem() / ClipItem.new instead')
  static ClipItem create() => ClipItem._();
  static $pb.GeneratedMessage $_createMessage() => ClipItem._();
  @$core.override
  ClipItem createEmptyInstance() => ClipItem._();
  @$core.pragma('dart2js:noInline')
  static ClipItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClipItem>(ClipItem.$_createMessage);
  static ClipItem? _defaultInstance;

  /// Random id chosen by the source device, used to drop duplicates.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ClipKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ClipKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Set for CLIP_KIND_TEXT and CLIP_KIND_URL.
  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  /// Encoded image bytes, set for CLIP_KIND_IMAGE.
  @$pb.TagNumber(4)
  $core.List<$core.int> get image => $_getN(3);
  @$pb.TagNumber(4)
  set image($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasImage() => $_has(3);
  @$pb.TagNumber(4)
  void clearImage() => $_clearField(4);

  /// Media type of `image`, such as "image/png".
  @$pb.TagNumber(5)
  $core.String get imageMime => $_getSZ(4);
  @$pb.TagNumber(5)
  set imageMime($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasImageMime() => $_has(4);
  @$pb.TagNumber(5)
  void clearImageMime() => $_clearField(5);

  /// When it was copied, in the source device's clock.
  @$pb.TagNumber(6)
  $fixnum.Int64 get createdAtMs => $_getI64(5);
  @$pb.TagNumber(6)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAtMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAtMs() => $_clearField(6);

  /// Device id of the device it was copied on.
  @$pb.TagNumber(7)
  $core.String get sourceDeviceId => $_getSZ(6);
  @$pb.TagNumber(7)
  set sourceDeviceId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSourceDeviceId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSourceDeviceId() => $_clearField(7);

  /// The source app marked it as private, such as a password manager.
  /// Receivers keep it out of history and clipboard managers.
  @$pb.TagNumber(8)
  $core.bool get sensitive => $_getBF(7);
  @$pb.TagNumber(8)
  set sensitive($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSensitive() => $_has(7);
  @$pb.TagNumber(8)
  void clearSensitive() => $_clearField(8);

  /// SHA-256 of the content (kind, text or image bytes), so devices can drop
  /// echoes of what they wrote themselves.
  @$pb.TagNumber(9)
  $core.List<$core.int> get contentHash => $_getN(8);
  @$pb.TagNumber(9)
  set contentHash($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasContentHash() => $_has(8);
  @$pb.TagNumber(9)
  void clearContentHash() => $_clearField(9);
}

/// Puts `item` on the receiver's clipboard. Sent without expecting a reply.
class ClipPush extends $pb.GeneratedMessage {
  factory ClipPush({
    ClipItem? item,
    $fixnum.Int64? expiresInMs,
  }) {
    final result = ClipPush._();
    if (item != null) result.item = item;
    if (expiresInMs != null) result.expiresInMs = expiresInMs;
    return result;
  }

  ClipPush._();

  factory ClipPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClipPush()..mergeFromBuffer(data, registry);
  factory ClipPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClipPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClipPush',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.clipboard.v1'),
      createEmptyInstance: ClipPush.$_createMessage)
    ..aOM<ClipItem>(1, _omitFieldNames ? '' : 'item',
        subBuilder: ClipItem.$_createMessage)
    ..aInt64(2, _omitFieldNames ? '' : 'expiresInMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClipPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClipPush copyWith(void Function(ClipPush) updates) =>
      super.copyWith((message) => updates(message as ClipPush)) as ClipPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClipPush() / ClipPush.new instead')
  static ClipPush create() => ClipPush._();
  static $pb.GeneratedMessage $_createMessage() => ClipPush._();
  @$core.override
  ClipPush createEmptyInstance() => ClipPush._();
  @$core.pragma('dart2js:noInline')
  static ClipPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClipPush>(ClipPush.$_createMessage);
  static ClipPush? _defaultInstance;

  @$pb.TagNumber(1)
  ClipItem get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(ClipItem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  ClipItem ensureItem() => $_ensure(0);

  /// How long the item stays useful after `created_at_ms`. Receivers drop
  /// sensitive items from memory once it passes.
  @$pb.TagNumber(2)
  $fixnum.Int64 get expiresInMs => $_getI64(1);
  @$pb.TagNumber(2)
  set expiresInMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresInMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresInMs() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
