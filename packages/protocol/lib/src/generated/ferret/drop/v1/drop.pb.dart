// This is a generated file - do not edit.
//
// Generated from ferret/drop/v1/drop.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'drop.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'drop.pbenum.dart';

/// One file in a transfer offer.
class FileInfo extends $pb.GeneratedMessage {
  factory FileInfo({
    $core.String? name,
    $fixnum.Int64? size,
    $core.String? mime,
    $core.List<$core.int>? sha256,
  }) {
    final result = FileInfo._();
    if (name != null) result.name = name;
    if (size != null) result.size = size;
    if (mime != null) result.mime = mime;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  FileInfo._();

  factory FileInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileInfo()..mergeFromBuffer(data, registry);
  factory FileInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: FileInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'mime')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'sha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileInfo copyWith(void Function(FileInfo) updates) =>
      super.copyWith((message) => updates(message as FileInfo)) as FileInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FileInfo() / FileInfo.new instead')
  static FileInfo create() => FileInfo._();
  static $pb.GeneratedMessage $_createMessage() => FileInfo._();
  @$core.override
  FileInfo createEmptyInstance() => FileInfo._();
  @$core.pragma('dart2js:noInline')
  static FileInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileInfo>(FileInfo.$_createMessage);
  static FileInfo? _defaultInstance;

  /// Base name only; the receiver never trusts it as a path.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get size => $_getI64(1);
  @$pb.TagNumber(2)
  set size($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mime => $_getSZ(2);
  @$pb.TagNumber(3)
  set mime($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMime() => $_has(2);
  @$pb.TagNumber(3)
  void clearMime() => $_clearField(3);

  /// SHA-256 of the whole file when the sender knows it up front. The
  /// authoritative hash always arrives in FileComplete.
  @$pb.TagNumber(4)
  $core.List<$core.int> get sha256 => $_getN(3);
  @$pb.TagNumber(4)
  set sha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearSha256() => $_clearField(4);
}

/// Asks to send files or text (a request, answered with TransferAnswer).
/// Sending the same transfer_id again after a dropped session resumes it.
class TransferOffer extends $pb.GeneratedMessage {
  factory TransferOffer({
    $core.String? transferId,
    $core.Iterable<FileInfo>? files,
    $core.String? text,
    $core.int? chunkSize,
  }) {
    final result = TransferOffer._();
    if (transferId != null) result.transferId = transferId;
    if (files != null) result.files.addAll(files);
    if (text != null) result.text = text;
    if (chunkSize != null) result.chunkSize = chunkSize;
    return result;
  }

  TransferOffer._();

  factory TransferOffer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferOffer()..mergeFromBuffer(data, registry);
  factory TransferOffer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferOffer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferOffer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: TransferOffer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..pPM<FileInfo>(2, _omitFieldNames ? '' : 'files',
        subBuilder: FileInfo.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aI(4, _omitFieldNames ? '' : 'chunkSize', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferOffer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferOffer copyWith(void Function(TransferOffer) updates) =>
      super.copyWith((message) => updates(message as TransferOffer))
          as TransferOffer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferOffer() / TransferOffer.new instead')
  static TransferOffer create() => TransferOffer._();
  static $pb.GeneratedMessage $_createMessage() => TransferOffer._();
  @$core.override
  TransferOffer createEmptyInstance() => TransferOffer._();
  @$core.pragma('dart2js:noInline')
  static TransferOffer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransferOffer>(
          TransferOffer.$_createMessage);
  static TransferOffer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<FileInfo> get files => $_getList(1);

  /// Text to drop instead of, or along with, files.
  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  /// Size of each chunk the sender will send.
  @$pb.TagNumber(4)
  $core.int get chunkSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set chunkSize($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChunkSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearChunkSize() => $_clearField(4);
}

/// The answer to a TransferOffer.
class TransferAnswer extends $pb.GeneratedMessage {
  factory TransferAnswer({
    $core.String? transferId,
    $core.bool? accepted,
    DeclineReason? reason,
    $core.int? fileIndex,
    $fixnum.Int64? offset,
  }) {
    final result = TransferAnswer._();
    if (transferId != null) result.transferId = transferId;
    if (accepted != null) result.accepted = accepted;
    if (reason != null) result.reason = reason;
    if (fileIndex != null) result.fileIndex = fileIndex;
    if (offset != null) result.offset = offset;
    return result;
  }

  TransferAnswer._();

  factory TransferAnswer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferAnswer()..mergeFromBuffer(data, registry);
  factory TransferAnswer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferAnswer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferAnswer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: TransferAnswer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aOB(2, _omitFieldNames ? '' : 'accepted')
    ..aE<DeclineReason>(3, _omitFieldNames ? '' : 'reason',
        enumValues: DeclineReason.values)
    ..aI(4, _omitFieldNames ? '' : 'fileIndex', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferAnswer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferAnswer copyWith(void Function(TransferAnswer) updates) =>
      super.copyWith((message) => updates(message as TransferAnswer))
          as TransferAnswer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferAnswer() / TransferAnswer.new instead')
  static TransferAnswer create() => TransferAnswer._();
  static $pb.GeneratedMessage $_createMessage() => TransferAnswer._();
  @$core.override
  TransferAnswer createEmptyInstance() => TransferAnswer._();
  @$core.pragma('dart2js:noInline')
  static TransferAnswer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransferAnswer>(
          TransferAnswer.$_createMessage);
  static TransferAnswer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get accepted => $_getBF(1);
  @$pb.TagNumber(2)
  set accepted($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccepted() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccepted() => $_clearField(2);

  @$pb.TagNumber(3)
  DeclineReason get reason => $_getN(2);
  @$pb.TagNumber(3)
  set reason(DeclineReason value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);

  /// Where to start sending: the first file that isn't complete yet and the
  /// byte offset in it. Both are 0 for a new transfer.
  @$pb.TagNumber(4)
  $core.int get fileIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set fileIndex($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFileIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearFileIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get offset => $_getI64(4);
  @$pb.TagNumber(5)
  set offset($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);
}

/// A piece of one file. Every few chunks are sent as a request, answered with
/// ChunkReceived once the receiver wrote them, which bounds the data in flight.
class Chunk extends $pb.GeneratedMessage {
  factory Chunk({
    $core.String? transferId,
    $core.int? fileIndex,
    $fixnum.Int64? offset,
    $core.List<$core.int>? data,
  }) {
    final result = Chunk._();
    if (transferId != null) result.transferId = transferId;
    if (fileIndex != null) result.fileIndex = fileIndex;
    if (offset != null) result.offset = offset;
    if (data != null) result.data = data;
    return result;
  }

  Chunk._();

  factory Chunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chunk()..mergeFromBuffer(data, registry);
  factory Chunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chunk()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Chunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: Chunk.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aI(2, _omitFieldNames ? '' : 'fileIndex', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chunk copyWith(void Function(Chunk) updates) =>
      super.copyWith((message) => updates(message as Chunk)) as Chunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Chunk() / Chunk.new instead')
  static Chunk create() => Chunk._();
  static $pb.GeneratedMessage $_createMessage() => Chunk._();
  @$core.override
  Chunk createEmptyInstance() => Chunk._();
  @$core.pragma('dart2js:noInline')
  static Chunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Chunk>(Chunk.$_createMessage);
  static Chunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get fileIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set fileIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offset => $_getI64(2);
  @$pb.TagNumber(3)
  set offset($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get data => $_getN(3);
  @$pb.TagNumber(4)
  set data($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => $_clearField(4);
}

/// Confirms the receiver wrote everything up to offset of file_index.
class ChunkReceived extends $pb.GeneratedMessage {
  factory ChunkReceived({
    $core.String? transferId,
    $core.int? fileIndex,
    $fixnum.Int64? offset,
  }) {
    final result = ChunkReceived._();
    if (transferId != null) result.transferId = transferId;
    if (fileIndex != null) result.fileIndex = fileIndex;
    if (offset != null) result.offset = offset;
    return result;
  }

  ChunkReceived._();

  factory ChunkReceived.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChunkReceived()..mergeFromBuffer(data, registry);
  factory ChunkReceived.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChunkReceived()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChunkReceived',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: ChunkReceived.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aI(2, _omitFieldNames ? '' : 'fileIndex', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChunkReceived clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChunkReceived copyWith(void Function(ChunkReceived) updates) =>
      super.copyWith((message) => updates(message as ChunkReceived))
          as ChunkReceived;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChunkReceived() / ChunkReceived.new instead')
  static ChunkReceived create() => ChunkReceived._();
  static $pb.GeneratedMessage $_createMessage() => ChunkReceived._();
  @$core.override
  ChunkReceived createEmptyInstance() => ChunkReceived._();
  @$core.pragma('dart2js:noInline')
  static ChunkReceived getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChunkReceived>(
          ChunkReceived.$_createMessage);
  static ChunkReceived? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get fileIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set fileIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offset => $_getI64(2);
  @$pb.TagNumber(3)
  set offset($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);
}

/// The last chunk of a file was sent (a request, answered with FileVerified).
class FileComplete extends $pb.GeneratedMessage {
  factory FileComplete({
    $core.String? transferId,
    $core.int? fileIndex,
    $core.List<$core.int>? sha256,
  }) {
    final result = FileComplete._();
    if (transferId != null) result.transferId = transferId;
    if (fileIndex != null) result.fileIndex = fileIndex;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  FileComplete._();

  factory FileComplete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileComplete()..mergeFromBuffer(data, registry);
  factory FileComplete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileComplete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileComplete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: FileComplete.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aI(2, _omitFieldNames ? '' : 'fileIndex', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'sha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileComplete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileComplete copyWith(void Function(FileComplete) updates) =>
      super.copyWith((message) => updates(message as FileComplete))
          as FileComplete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FileComplete() / FileComplete.new instead')
  static FileComplete create() => FileComplete._();
  static $pb.GeneratedMessage $_createMessage() => FileComplete._();
  @$core.override
  FileComplete createEmptyInstance() => FileComplete._();
  @$core.pragma('dart2js:noInline')
  static FileComplete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileComplete>(
          FileComplete.$_createMessage);
  static FileComplete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get fileIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set fileIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get sha256 => $_getN(2);
  @$pb.TagNumber(3)
  set sha256($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha256() => $_clearField(3);
}

/// Whether the receiver's copy matched the hash and was saved.
class FileVerified extends $pb.GeneratedMessage {
  factory FileVerified({
    $core.String? transferId,
    $core.int? fileIndex,
    $core.bool? ok,
    FailureReason? reason,
  }) {
    final result = FileVerified._();
    if (transferId != null) result.transferId = transferId;
    if (fileIndex != null) result.fileIndex = fileIndex;
    if (ok != null) result.ok = ok;
    if (reason != null) result.reason = reason;
    return result;
  }

  FileVerified._();

  factory FileVerified.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileVerified()..mergeFromBuffer(data, registry);
  factory FileVerified.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileVerified()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVerified',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: FileVerified.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aI(2, _omitFieldNames ? '' : 'fileIndex', fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'ok')
    ..aE<FailureReason>(4, _omitFieldNames ? '' : 'reason',
        enumValues: FailureReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVerified clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVerified copyWith(void Function(FileVerified) updates) =>
      super.copyWith((message) => updates(message as FileVerified))
          as FileVerified;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FileVerified() / FileVerified.new instead')
  static FileVerified create() => FileVerified._();
  static $pb.GeneratedMessage $_createMessage() => FileVerified._();
  @$core.override
  FileVerified createEmptyInstance() => FileVerified._();
  @$core.pragma('dart2js:noInline')
  static FileVerified getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileVerified>(
          FileVerified.$_createMessage);
  static FileVerified? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get fileIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set fileIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get ok => $_getBF(2);
  @$pb.TagNumber(3)
  set ok($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOk() => $_has(2);
  @$pb.TagNumber(3)
  void clearOk() => $_clearField(3);

  @$pb.TagNumber(4)
  FailureReason get reason => $_getN(3);
  @$pb.TagNumber(4)
  set reason(FailureReason value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);
}

/// Every file was sent and verified.
class TransferComplete extends $pb.GeneratedMessage {
  factory TransferComplete({
    $core.String? transferId,
  }) {
    final result = TransferComplete._();
    if (transferId != null) result.transferId = transferId;
    return result;
  }

  TransferComplete._();

  factory TransferComplete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferComplete()..mergeFromBuffer(data, registry);
  factory TransferComplete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferComplete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferComplete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: TransferComplete.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferComplete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferComplete copyWith(void Function(TransferComplete) updates) =>
      super.copyWith((message) => updates(message as TransferComplete))
          as TransferComplete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferComplete() / TransferComplete.new instead')
  static TransferComplete create() => TransferComplete._();
  static $pb.GeneratedMessage $_createMessage() => TransferComplete._();
  @$core.override
  TransferComplete createEmptyInstance() => TransferComplete._();
  @$core.pragma('dart2js:noInline')
  static TransferComplete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransferComplete>(
          TransferComplete.$_createMessage);
  static TransferComplete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);
}

/// Either side stops a transfer.
class Cancel extends $pb.GeneratedMessage {
  factory Cancel({
    $core.String? transferId,
    FailureReason? reason,
  }) {
    final result = Cancel._();
    if (transferId != null) result.transferId = transferId;
    if (reason != null) result.reason = reason;
    return result;
  }

  Cancel._();

  factory Cancel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Cancel()..mergeFromBuffer(data, registry);
  factory Cancel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Cancel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Cancel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: Cancel.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aE<FailureReason>(2, _omitFieldNames ? '' : 'reason',
        enumValues: FailureReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cancel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cancel copyWith(void Function(Cancel) updates) =>
      super.copyWith((message) => updates(message as Cancel)) as Cancel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Cancel() / Cancel.new instead')
  static Cancel create() => Cancel._();
  static $pb.GeneratedMessage $_createMessage() => Cancel._();
  @$core.override
  Cancel createEmptyInstance() => Cancel._();
  @$core.pragma('dart2js:noInline')
  static Cancel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Cancel>(Cancel.$_createMessage);
  static Cancel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  FailureReason get reason => $_getN(1);
  @$pb.TagNumber(2)
  set reason(FailureReason value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

/// Sent by a receiver after a dropped session comes back, to continue an
/// interrupted transfer where it stopped.
class ResumeRequest extends $pb.GeneratedMessage {
  factory ResumeRequest({
    $core.String? transferId,
    $core.int? fileIndex,
    $fixnum.Int64? offset,
  }) {
    final result = ResumeRequest._();
    if (transferId != null) result.transferId = transferId;
    if (fileIndex != null) result.fileIndex = fileIndex;
    if (offset != null) result.offset = offset;
    return result;
  }

  ResumeRequest._();

  factory ResumeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResumeRequest()..mergeFromBuffer(data, registry);
  factory ResumeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResumeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResumeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.drop.v1'),
      createEmptyInstance: ResumeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aI(2, _omitFieldNames ? '' : 'fileIndex', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeRequest copyWith(void Function(ResumeRequest) updates) =>
      super.copyWith((message) => updates(message as ResumeRequest))
          as ResumeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResumeRequest() / ResumeRequest.new instead')
  static ResumeRequest create() => ResumeRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResumeRequest._();
  @$core.override
  ResumeRequest createEmptyInstance() => ResumeRequest._();
  @$core.pragma('dart2js:noInline')
  static ResumeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResumeRequest>(
          ResumeRequest.$_createMessage);
  static ResumeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get fileIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set fileIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offset => $_getI64(2);
  @$pb.TagNumber(3)
  set offset($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
