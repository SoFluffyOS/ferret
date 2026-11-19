// This is a generated file - do not edit.
//
// Generated from ferret/photos/v1/photos.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'photos.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'photos.pbenum.dart';

/// One photo or video on the phone. Ids are opaque and only mean something
/// to the phone that sent them.
class PhotoItem extends $pb.GeneratedMessage {
  factory PhotoItem({
    $core.String? id,
    $fixnum.Int64? takenAtMs,
    $core.int? width,
    $core.int? height,
    PhotoKind? kind,
    $fixnum.Int64? size,
    $core.String? name,
    $core.int? durationMs,
  }) {
    final result = PhotoItem._();
    if (id != null) result.id = id;
    if (takenAtMs != null) result.takenAtMs = takenAtMs;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (kind != null) result.kind = kind;
    if (size != null) result.size = size;
    if (name != null) result.name = name;
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  PhotoItem._();

  factory PhotoItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoItem()..mergeFromBuffer(data, registry);
  factory PhotoItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: PhotoItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'takenAtMs')
    ..aI(3, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aE<PhotoKind>(5, _omitFieldNames ? '' : 'kind',
        enumValues: PhotoKind.values)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(7, _omitFieldNames ? '' : 'name')
    ..aI(8, _omitFieldNames ? '' : 'durationMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoItem copyWith(void Function(PhotoItem) updates) =>
      super.copyWith((message) => updates(message as PhotoItem)) as PhotoItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PhotoItem() / PhotoItem.new instead')
  static PhotoItem create() => PhotoItem._();
  static $pb.GeneratedMessage $_createMessage() => PhotoItem._();
  @$core.override
  PhotoItem createEmptyInstance() => PhotoItem._();
  @$core.pragma('dart2js:noInline')
  static PhotoItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PhotoItem>(PhotoItem.$_createMessage);
  static PhotoItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// When it was taken (or added), in milliseconds since the Unix epoch.
  @$pb.TagNumber(2)
  $fixnum.Int64 get takenAtMs => $_getI64(1);
  @$pb.TagNumber(2)
  set takenAtMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTakenAtMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTakenAtMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => $_clearField(4);

  @$pb.TagNumber(5)
  PhotoKind get kind => $_getN(4);
  @$pb.TagNumber(5)
  set kind(PhotoKind value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  /// Bytes, or 0 when unknown.
  @$pb.TagNumber(6)
  $fixnum.Int64 get size => $_getI64(5);
  @$pb.TagNumber(6)
  set size($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSize() => $_has(5);
  @$pb.TagNumber(6)
  void clearSize() => $_clearField(6);

  /// The file name on the phone, such as "IMG_2041.jpg".
  @$pb.TagNumber(7)
  $core.String get name => $_getSZ(6);
  @$pb.TagNumber(7)
  set name($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasName() => $_has(6);
  @$pb.TagNumber(7)
  void clearName() => $_clearField(7);

  /// Videos only.
  @$pb.TagNumber(8)
  $core.int get durationMs => $_getIZ(7);
  @$pb.TagNumber(8)
  set durationMs($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDurationMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearDurationMs() => $_clearField(8);
}

/// Asks for a page of photos, newest first (a request, answered with
/// PhotoList).
class PhotoListRequest extends $pb.GeneratedMessage {
  factory PhotoListRequest({
    $core.String? cursor,
    $core.int? limit,
  }) {
    final result = PhotoListRequest._();
    if (cursor != null) result.cursor = cursor;
    if (limit != null) result.limit = limit;
    return result;
  }

  PhotoListRequest._();

  factory PhotoListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoListRequest()..mergeFromBuffer(data, registry);
  factory PhotoListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoListRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoListRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: PhotoListRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'cursor')
    ..aI(2, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoListRequest copyWith(void Function(PhotoListRequest) updates) =>
      super.copyWith((message) => updates(message as PhotoListRequest))
          as PhotoListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PhotoListRequest() / PhotoListRequest.new instead')
  static PhotoListRequest create() => PhotoListRequest._();
  static $pb.GeneratedMessage $_createMessage() => PhotoListRequest._();
  @$core.override
  PhotoListRequest createEmptyInstance() => PhotoListRequest._();
  @$core.pragma('dart2js:noInline')
  static PhotoListRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PhotoListRequest>(
          PhotoListRequest.$_createMessage);
  static PhotoListRequest? _defaultInstance;

  /// Empty for the first page, else the previous page's next_cursor.
  @$pb.TagNumber(1)
  $core.String get cursor => $_getSZ(0);
  @$pb.TagNumber(1)
  set cursor($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursor() => $_clearField(1);

  /// At most this many; the phone may send fewer and caps it at 200.
  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class PhotoList extends $pb.GeneratedMessage {
  factory PhotoList({
    $core.Iterable<PhotoItem>? items,
    $core.String? nextCursor,
    PhotoAccess? access,
    $core.int? total,
  }) {
    final result = PhotoList._();
    if (items != null) result.items.addAll(items);
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (access != null) result.access = access;
    if (total != null) result.total = total;
    return result;
  }

  PhotoList._();

  factory PhotoList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoList()..mergeFromBuffer(data, registry);
  factory PhotoList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: PhotoList.$_createMessage)
    ..pPM<PhotoItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: PhotoItem.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'nextCursor')
    ..aE<PhotoAccess>(3, _omitFieldNames ? '' : 'access',
        enumValues: PhotoAccess.values)
    ..aI(4, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoList copyWith(void Function(PhotoList) updates) =>
      super.copyWith((message) => updates(message as PhotoList)) as PhotoList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PhotoList() / PhotoList.new instead')
  static PhotoList create() => PhotoList._();
  static $pb.GeneratedMessage $_createMessage() => PhotoList._();
  @$core.override
  PhotoList createEmptyInstance() => PhotoList._();
  @$core.pragma('dart2js:noInline')
  static PhotoList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PhotoList>(PhotoList.$_createMessage);
  static PhotoList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PhotoItem> get items => $_getList(0);

  /// Empty when this was the last page.
  @$pb.TagNumber(2)
  $core.String get nextCursor => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextCursor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextCursor() => $_clearField(2);

  @$pb.TagNumber(3)
  PhotoAccess get access => $_getN(2);
  @$pb.TagNumber(3)
  set access(PhotoAccess value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAccess() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccess() => $_clearField(3);

  /// How many photos the asking device can see in all, or 0 when unknown.
  @$pb.TagNumber(4)
  $core.int get total => $_getIZ(3);
  @$pb.TagNumber(4)
  set total($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotal() => $_clearField(4);
}

/// Asks for a small JPEG of one photo (a request, answered with Thumbnail).
class ThumbnailRequest extends $pb.GeneratedMessage {
  factory ThumbnailRequest({
    $core.String? id,
    $core.int? maxPx,
  }) {
    final result = ThumbnailRequest._();
    if (id != null) result.id = id;
    if (maxPx != null) result.maxPx = maxPx;
    return result;
  }

  ThumbnailRequest._();

  factory ThumbnailRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ThumbnailRequest()..mergeFromBuffer(data, registry);
  factory ThumbnailRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ThumbnailRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThumbnailRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: ThumbnailRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'maxPx', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThumbnailRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThumbnailRequest copyWith(void Function(ThumbnailRequest) updates) =>
      super.copyWith((message) => updates(message as ThumbnailRequest))
          as ThumbnailRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ThumbnailRequest() / ThumbnailRequest.new instead')
  static ThumbnailRequest create() => ThumbnailRequest._();
  static $pb.GeneratedMessage $_createMessage() => ThumbnailRequest._();
  @$core.override
  ThumbnailRequest createEmptyInstance() => ThumbnailRequest._();
  @$core.pragma('dart2js:noInline')
  static ThumbnailRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ThumbnailRequest>(
          ThumbnailRequest.$_createMessage);
  static ThumbnailRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The longest side, in pixels. The phone caps it at 2048.
  @$pb.TagNumber(2)
  $core.int get maxPx => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxPx($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxPx() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxPx() => $_clearField(2);
}

class Thumbnail extends $pb.GeneratedMessage {
  factory Thumbnail({
    $core.String? id,
    $core.List<$core.int>? jpeg,
    PhotoAccess? access,
  }) {
    final result = Thumbnail._();
    if (id != null) result.id = id;
    if (jpeg != null) result.jpeg = jpeg;
    if (access != null) result.access = access;
    return result;
  }

  Thumbnail._();

  factory Thumbnail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Thumbnail()..mergeFromBuffer(data, registry);
  factory Thumbnail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Thumbnail()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Thumbnail',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: Thumbnail.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'jpeg', $pb.PbFieldType.OY)
    ..aE<PhotoAccess>(3, _omitFieldNames ? '' : 'access',
        enumValues: PhotoAccess.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Thumbnail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Thumbnail copyWith(void Function(Thumbnail) updates) =>
      super.copyWith((message) => updates(message as Thumbnail)) as Thumbnail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Thumbnail() / Thumbnail.new instead')
  static Thumbnail create() => Thumbnail._();
  static $pb.GeneratedMessage $_createMessage() => Thumbnail._();
  @$core.override
  Thumbnail createEmptyInstance() => Thumbnail._();
  @$core.pragma('dart2js:noInline')
  static Thumbnail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Thumbnail>(Thumbnail.$_createMessage);
  static Thumbnail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Empty when the photo is gone or the access changed; see access.
  @$pb.TagNumber(2)
  $core.List<$core.int> get jpeg => $_getN(1);
  @$pb.TagNumber(2)
  set jpeg($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasJpeg() => $_has(1);
  @$pb.TagNumber(2)
  void clearJpeg() => $_clearField(2);

  @$pb.TagNumber(3)
  PhotoAccess get access => $_getN(2);
  @$pb.TagNumber(3)
  set access(PhotoAccess value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAccess() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccess() => $_clearField(3);
}

/// Asks the phone to send these photos' full files through drop (a request,
/// answered with PhotoFetchReply). The asking device accepts that transfer
/// on its own: it asked for it.
class PhotoFetchRequest extends $pb.GeneratedMessage {
  factory PhotoFetchRequest({
    $core.Iterable<$core.String>? ids,
  }) {
    final result = PhotoFetchRequest._();
    if (ids != null) result.ids.addAll(ids);
    return result;
  }

  PhotoFetchRequest._();

  factory PhotoFetchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoFetchRequest()..mergeFromBuffer(data, registry);
  factory PhotoFetchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoFetchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoFetchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: PhotoFetchRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'ids')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFetchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFetchRequest copyWith(void Function(PhotoFetchRequest) updates) =>
      super.copyWith((message) => updates(message as PhotoFetchRequest))
          as PhotoFetchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PhotoFetchRequest() / PhotoFetchRequest.new instead')
  static PhotoFetchRequest create() => PhotoFetchRequest._();
  static $pb.GeneratedMessage $_createMessage() => PhotoFetchRequest._();
  @$core.override
  PhotoFetchRequest createEmptyInstance() => PhotoFetchRequest._();
  @$core.pragma('dart2js:noInline')
  static PhotoFetchRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PhotoFetchRequest>(
          PhotoFetchRequest.$_createMessage);
  static PhotoFetchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get ids => $_getList(0);
}

class PhotoFetchReply extends $pb.GeneratedMessage {
  factory PhotoFetchReply({
    $core.String? transferId,
    PhotoAccess? access,
    $core.int? missing,
  }) {
    final result = PhotoFetchReply._();
    if (transferId != null) result.transferId = transferId;
    if (access != null) result.access = access;
    if (missing != null) result.missing = missing;
    return result;
  }

  PhotoFetchReply._();

  factory PhotoFetchReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoFetchReply()..mergeFromBuffer(data, registry);
  factory PhotoFetchReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoFetchReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoFetchReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: PhotoFetchReply.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aE<PhotoAccess>(2, _omitFieldNames ? '' : 'access',
        enumValues: PhotoAccess.values)
    ..aI(3, _omitFieldNames ? '' : 'missing', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFetchReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFetchReply copyWith(void Function(PhotoFetchReply) updates) =>
      super.copyWith((message) => updates(message as PhotoFetchReply))
          as PhotoFetchReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PhotoFetchReply() / PhotoFetchReply.new instead')
  static PhotoFetchReply create() => PhotoFetchReply._();
  static $pb.GeneratedMessage $_createMessage() => PhotoFetchReply._();
  @$core.override
  PhotoFetchReply createEmptyInstance() => PhotoFetchReply._();
  @$core.pragma('dart2js:noInline')
  static PhotoFetchReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PhotoFetchReply>(
          PhotoFetchReply.$_createMessage);
  static PhotoFetchReply? _defaultInstance;

  /// The drop transfer that carries the files, or empty when none could be
  /// sent.
  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  PhotoAccess get access => $_getN(1);
  @$pb.TagNumber(2)
  set access(PhotoAccess value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccess() => $_clearField(2);

  /// How many of the asked ids weren't found any more.
  @$pb.TagNumber(3)
  $core.int get missing => $_getIZ(2);
  @$pb.TagNumber(3)
  set missing($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMissing() => $_has(2);
  @$pb.TagNumber(3)
  void clearMissing() => $_clearField(3);
}

/// Tells the phone whether the sender wants new screenshots sent to it as
/// soon as they are taken, while Ferret runs. Sent again after each
/// reconnect; the phone forgets it when the session ends. No reply.
class ScreenshotSubscription extends $pb.GeneratedMessage {
  factory ScreenshotSubscription({
    $core.bool? enabled,
  }) {
    final result = ScreenshotSubscription._();
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  ScreenshotSubscription._();

  factory ScreenshotSubscription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScreenshotSubscription()..mergeFromBuffer(data, registry);
  factory ScreenshotSubscription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScreenshotSubscription()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScreenshotSubscription',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: ScreenshotSubscription.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScreenshotSubscription clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScreenshotSubscription copyWith(
          void Function(ScreenshotSubscription) updates) =>
      super.copyWith((message) => updates(message as ScreenshotSubscription))
          as ScreenshotSubscription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ScreenshotSubscription() / ScreenshotSubscription.new instead')
  static ScreenshotSubscription create() => ScreenshotSubscription._();
  static $pb.GeneratedMessage $_createMessage() => ScreenshotSubscription._();
  @$core.override
  ScreenshotSubscription createEmptyInstance() => ScreenshotSubscription._();
  @$core.pragma('dart2js:noInline')
  static ScreenshotSubscription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScreenshotSubscription>(
          ScreenshotSubscription.$_createMessage);
  static ScreenshotSubscription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);
}

/// The phone is sending a new screenshot through drop. Sent just before that
/// transfer's offer. No reply.
class ScreenshotSent extends $pb.GeneratedMessage {
  factory ScreenshotSent({
    $core.String? transferId,
    PhotoItem? item,
  }) {
    final result = ScreenshotSent._();
    if (transferId != null) result.transferId = transferId;
    if (item != null) result.item = item;
    return result;
  }

  ScreenshotSent._();

  factory ScreenshotSent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScreenshotSent()..mergeFromBuffer(data, registry);
  factory ScreenshotSent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScreenshotSent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScreenshotSent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: ScreenshotSent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aOM<PhotoItem>(2, _omitFieldNames ? '' : 'item',
        subBuilder: PhotoItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScreenshotSent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScreenshotSent copyWith(void Function(ScreenshotSent) updates) =>
      super.copyWith((message) => updates(message as ScreenshotSent))
          as ScreenshotSent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ScreenshotSent() / ScreenshotSent.new instead')
  static ScreenshotSent create() => ScreenshotSent._();
  static $pb.GeneratedMessage $_createMessage() => ScreenshotSent._();
  @$core.override
  ScreenshotSent createEmptyInstance() => ScreenshotSent._();
  @$core.pragma('dart2js:noInline')
  static ScreenshotSent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScreenshotSent>(
          ScreenshotSent.$_createMessage);
  static ScreenshotSent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  PhotoItem get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(PhotoItem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  PhotoItem ensureItem() => $_ensure(1);
}

/// Asks the phone's owner to share photos with the sender, or more of them.
/// The phone shows a notice; nothing changes until its owner acts. No reply.
class PhotoAccessPrompt extends $pb.GeneratedMessage {
  factory PhotoAccessPrompt() => PhotoAccessPrompt._();

  PhotoAccessPrompt._();

  factory PhotoAccessPrompt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoAccessPrompt()..mergeFromBuffer(data, registry);
  factory PhotoAccessPrompt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PhotoAccessPrompt()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoAccessPrompt',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.photos.v1'),
      createEmptyInstance: PhotoAccessPrompt.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoAccessPrompt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoAccessPrompt copyWith(void Function(PhotoAccessPrompt) updates) =>
      super.copyWith((message) => updates(message as PhotoAccessPrompt))
          as PhotoAccessPrompt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PhotoAccessPrompt() / PhotoAccessPrompt.new instead')
  static PhotoAccessPrompt create() => PhotoAccessPrompt._();
  static $pb.GeneratedMessage $_createMessage() => PhotoAccessPrompt._();
  @$core.override
  PhotoAccessPrompt createEmptyInstance() => PhotoAccessPrompt._();
  @$core.pragma('dart2js:noInline')
  static PhotoAccessPrompt getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PhotoAccessPrompt>(
          PhotoAccessPrompt.$_createMessage);
  static PhotoAccessPrompt? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
