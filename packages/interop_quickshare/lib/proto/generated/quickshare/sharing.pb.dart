// This is a generated file - do not edit.
//
// Generated from quickshare/sharing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sharing.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'sharing.pbenum.dart';

class SharingFrame extends $pb.GeneratedMessage {
  factory SharingFrame({
    SharingFrame_Version? version,
    SharingFrameV1? v1,
  }) {
    final result = SharingFrame._();
    if (version != null) result.version = version;
    if (v1 != null) result.v1 = v1;
    return result;
  }

  SharingFrame._();

  factory SharingFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SharingFrame()..mergeFromBuffer(data, registry);
  factory SharingFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SharingFrame()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharingFrame',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: SharingFrame.$_createMessage)
    ..aE<SharingFrame_Version>(1, _omitFieldNames ? '' : 'version',
        enumValues: SharingFrame_Version.values)
    ..aOM<SharingFrameV1>(2, _omitFieldNames ? '' : 'v1',
        subBuilder: SharingFrameV1.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharingFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharingFrame copyWith(void Function(SharingFrame) updates) =>
      super.copyWith((message) => updates(message as SharingFrame))
          as SharingFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SharingFrame() / SharingFrame.new instead')
  static SharingFrame create() => SharingFrame._();
  static $pb.GeneratedMessage $_createMessage() => SharingFrame._();
  @$core.override
  SharingFrame createEmptyInstance() => SharingFrame._();
  @$core.pragma('dart2js:noInline')
  static SharingFrame getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SharingFrame>(
          SharingFrame.$_createMessage);
  static SharingFrame? _defaultInstance;

  @$pb.TagNumber(1)
  SharingFrame_Version get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(SharingFrame_Version value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  SharingFrameV1 get v1 => $_getN(1);
  @$pb.TagNumber(2)
  set v1(SharingFrameV1 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasV1() => $_has(1);
  @$pb.TagNumber(2)
  void clearV1() => $_clearField(2);
  @$pb.TagNumber(2)
  SharingFrameV1 ensureV1() => $_ensure(1);
}

class SharingFrameV1 extends $pb.GeneratedMessage {
  factory SharingFrameV1({
    SharingFrameV1_FrameType? type,
    Introduction? introduction,
    TransferResponse? connectionResponse,
    PairedKeyEncryption? pairedKeyEncryption,
    PairedKeyResult? pairedKeyResult,
  }) {
    final result = SharingFrameV1._();
    if (type != null) result.type = type;
    if (introduction != null) result.introduction = introduction;
    if (connectionResponse != null)
      result.connectionResponse = connectionResponse;
    if (pairedKeyEncryption != null)
      result.pairedKeyEncryption = pairedKeyEncryption;
    if (pairedKeyResult != null) result.pairedKeyResult = pairedKeyResult;
    return result;
  }

  SharingFrameV1._();

  factory SharingFrameV1.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SharingFrameV1()..mergeFromBuffer(data, registry);
  factory SharingFrameV1.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SharingFrameV1()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharingFrameV1',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: SharingFrameV1.$_createMessage)
    ..aE<SharingFrameV1_FrameType>(1, _omitFieldNames ? '' : 'type',
        enumValues: SharingFrameV1_FrameType.values)
    ..aOM<Introduction>(2, _omitFieldNames ? '' : 'introduction',
        subBuilder: Introduction.$_createMessage)
    ..aOM<TransferResponse>(3, _omitFieldNames ? '' : 'connectionResponse',
        subBuilder: TransferResponse.$_createMessage)
    ..aOM<PairedKeyEncryption>(4, _omitFieldNames ? '' : 'pairedKeyEncryption',
        subBuilder: PairedKeyEncryption.$_createMessage)
    ..aOM<PairedKeyResult>(5, _omitFieldNames ? '' : 'pairedKeyResult',
        subBuilder: PairedKeyResult.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharingFrameV1 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharingFrameV1 copyWith(void Function(SharingFrameV1) updates) =>
      super.copyWith((message) => updates(message as SharingFrameV1))
          as SharingFrameV1;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SharingFrameV1() / SharingFrameV1.new instead')
  static SharingFrameV1 create() => SharingFrameV1._();
  static $pb.GeneratedMessage $_createMessage() => SharingFrameV1._();
  @$core.override
  SharingFrameV1 createEmptyInstance() => SharingFrameV1._();
  @$core.pragma('dart2js:noInline')
  static SharingFrameV1 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SharingFrameV1>(
          SharingFrameV1.$_createMessage);
  static SharingFrameV1? _defaultInstance;

  @$pb.TagNumber(1)
  SharingFrameV1_FrameType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SharingFrameV1_FrameType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  Introduction get introduction => $_getN(1);
  @$pb.TagNumber(2)
  set introduction(Introduction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasIntroduction() => $_has(1);
  @$pb.TagNumber(2)
  void clearIntroduction() => $_clearField(2);
  @$pb.TagNumber(2)
  Introduction ensureIntroduction() => $_ensure(1);

  @$pb.TagNumber(3)
  TransferResponse get connectionResponse => $_getN(2);
  @$pb.TagNumber(3)
  set connectionResponse(TransferResponse value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConnectionResponse() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnectionResponse() => $_clearField(3);
  @$pb.TagNumber(3)
  TransferResponse ensureConnectionResponse() => $_ensure(2);

  @$pb.TagNumber(4)
  PairedKeyEncryption get pairedKeyEncryption => $_getN(3);
  @$pb.TagNumber(4)
  set pairedKeyEncryption(PairedKeyEncryption value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPairedKeyEncryption() => $_has(3);
  @$pb.TagNumber(4)
  void clearPairedKeyEncryption() => $_clearField(4);
  @$pb.TagNumber(4)
  PairedKeyEncryption ensurePairedKeyEncryption() => $_ensure(3);

  @$pb.TagNumber(5)
  PairedKeyResult get pairedKeyResult => $_getN(4);
  @$pb.TagNumber(5)
  set pairedKeyResult(PairedKeyResult value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPairedKeyResult() => $_has(4);
  @$pb.TagNumber(5)
  void clearPairedKeyResult() => $_clearField(5);
  @$pb.TagNumber(5)
  PairedKeyResult ensurePairedKeyResult() => $_ensure(4);
}

class FileMetadata extends $pb.GeneratedMessage {
  factory FileMetadata({
    $core.String? name,
    FileMetadata_Type? type,
    $fixnum.Int64? payloadId,
    $fixnum.Int64? size,
    $core.String? mimeType,
    $fixnum.Int64? id,
    $core.String? parentFolder,
  }) {
    final result = FileMetadata._();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (payloadId != null) result.payloadId = payloadId;
    if (size != null) result.size = size;
    if (mimeType != null) result.mimeType = mimeType;
    if (id != null) result.id = id;
    if (parentFolder != null) result.parentFolder = parentFolder;
    return result;
  }

  FileMetadata._();

  factory FileMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileMetadata()..mergeFromBuffer(data, registry);
  factory FileMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FileMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: FileMetadata.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<FileMetadata_Type>(2, _omitFieldNames ? '' : 'type',
        enumValues: FileMetadata_Type.values)
    ..aInt64(3, _omitFieldNames ? '' : 'payloadId')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..aOS(5, _omitFieldNames ? '' : 'mimeType')
    ..aInt64(6, _omitFieldNames ? '' : 'id')
    ..aOS(7, _omitFieldNames ? '' : 'parentFolder')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileMetadata copyWith(void Function(FileMetadata) updates) =>
      super.copyWith((message) => updates(message as FileMetadata))
          as FileMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FileMetadata() / FileMetadata.new instead')
  static FileMetadata create() => FileMetadata._();
  static $pb.GeneratedMessage $_createMessage() => FileMetadata._();
  @$core.override
  FileMetadata createEmptyInstance() => FileMetadata._();
  @$core.pragma('dart2js:noInline')
  static FileMetadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileMetadata>(
          FileMetadata.$_createMessage);
  static FileMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  FileMetadata_Type get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(FileMetadata_Type value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// The id the file's chunks carry in the connection layer.
  @$pb.TagNumber(3)
  $fixnum.Int64 get payloadId => $_getI64(2);
  @$pb.TagNumber(3)
  set payloadId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPayloadId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayloadId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get mimeType => $_getSZ(4);
  @$pb.TagNumber(5)
  set mimeType($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMimeType() => $_has(4);
  @$pb.TagNumber(5)
  void clearMimeType() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get id => $_getI64(5);
  @$pb.TagNumber(6)
  set id($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasId() => $_has(5);
  @$pb.TagNumber(6)
  void clearId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get parentFolder => $_getSZ(6);
  @$pb.TagNumber(7)
  set parentFolder($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasParentFolder() => $_has(6);
  @$pb.TagNumber(7)
  void clearParentFolder() => $_clearField(7);
}

class TextMetadata extends $pb.GeneratedMessage {
  factory TextMetadata({
    $core.String? textTitle,
    TextMetadata_Type? type,
    $fixnum.Int64? payloadId,
    $fixnum.Int64? size,
    $fixnum.Int64? id,
  }) {
    final result = TextMetadata._();
    if (textTitle != null) result.textTitle = textTitle;
    if (type != null) result.type = type;
    if (payloadId != null) result.payloadId = payloadId;
    if (size != null) result.size = size;
    if (id != null) result.id = id;
    return result;
  }

  TextMetadata._();

  factory TextMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextMetadata()..mergeFromBuffer(data, registry);
  factory TextMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: TextMetadata.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'textTitle')
    ..aE<TextMetadata_Type>(3, _omitFieldNames ? '' : 'type',
        enumValues: TextMetadata_Type.values)
    ..aInt64(4, _omitFieldNames ? '' : 'payloadId')
    ..aInt64(5, _omitFieldNames ? '' : 'size')
    ..aInt64(6, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextMetadata copyWith(void Function(TextMetadata) updates) =>
      super.copyWith((message) => updates(message as TextMetadata))
          as TextMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TextMetadata() / TextMetadata.new instead')
  static TextMetadata create() => TextMetadata._();
  static $pb.GeneratedMessage $_createMessage() => TextMetadata._();
  @$core.override
  TextMetadata createEmptyInstance() => TextMetadata._();
  @$core.pragma('dart2js:noInline')
  static TextMetadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextMetadata>(
          TextMetadata.$_createMessage);
  static TextMetadata? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get textTitle => $_getSZ(0);
  @$pb.TagNumber(2)
  set textTitle($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasTextTitle() => $_has(0);
  @$pb.TagNumber(2)
  void clearTextTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  TextMetadata_Type get type => $_getN(1);
  @$pb.TagNumber(3)
  set type(TextMetadata_Type value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get payloadId => $_getI64(2);
  @$pb.TagNumber(4)
  set payloadId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasPayloadId() => $_has(2);
  @$pb.TagNumber(4)
  void clearPayloadId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(5)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(5)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(5)
  void clearSize() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get id => $_getI64(4);
  @$pb.TagNumber(6)
  set id($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(6)
  $core.bool hasId() => $_has(4);
  @$pb.TagNumber(6)
  void clearId() => $_clearField(6);
}

/// Wi-Fi passwords shared from a phone. Ferret only counts them, to say it
/// can't take them.
class WifiCredentialsMetadata extends $pb.GeneratedMessage {
  factory WifiCredentialsMetadata({
    $core.String? ssid,
    $fixnum.Int64? payloadId,
    $fixnum.Int64? id,
  }) {
    final result = WifiCredentialsMetadata._();
    if (ssid != null) result.ssid = ssid;
    if (payloadId != null) result.payloadId = payloadId;
    if (id != null) result.id = id;
    return result;
  }

  WifiCredentialsMetadata._();

  factory WifiCredentialsMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WifiCredentialsMetadata()..mergeFromBuffer(data, registry);
  factory WifiCredentialsMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WifiCredentialsMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WifiCredentialsMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: WifiCredentialsMetadata.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'ssid')
    ..aInt64(4, _omitFieldNames ? '' : 'payloadId')
    ..aInt64(5, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WifiCredentialsMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WifiCredentialsMetadata copyWith(
          void Function(WifiCredentialsMetadata) updates) =>
      super.copyWith((message) => updates(message as WifiCredentialsMetadata))
          as WifiCredentialsMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use WifiCredentialsMetadata() / WifiCredentialsMetadata.new instead')
  static WifiCredentialsMetadata create() => WifiCredentialsMetadata._();
  static $pb.GeneratedMessage $_createMessage() => WifiCredentialsMetadata._();
  @$core.override
  WifiCredentialsMetadata createEmptyInstance() => WifiCredentialsMetadata._();
  @$core.pragma('dart2js:noInline')
  static WifiCredentialsMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WifiCredentialsMetadata>(
          WifiCredentialsMetadata.$_createMessage);
  static WifiCredentialsMetadata? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get ssid => $_getSZ(0);
  @$pb.TagNumber(2)
  set ssid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasSsid() => $_has(0);
  @$pb.TagNumber(2)
  void clearSsid() => $_clearField(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get payloadId => $_getI64(1);
  @$pb.TagNumber(4)
  set payloadId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(4)
  $core.bool hasPayloadId() => $_has(1);
  @$pb.TagNumber(4)
  void clearPayloadId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get id => $_getI64(2);
  @$pb.TagNumber(5)
  set id($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(5)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(5)
  void clearId() => $_clearField(5);
}

class Introduction extends $pb.GeneratedMessage {
  factory Introduction({
    $core.Iterable<FileMetadata>? fileMetadata,
    $core.Iterable<TextMetadata>? textMetadata,
    $core.String? requiredPackage,
    $core.Iterable<WifiCredentialsMetadata>? wifiCredentialsMetadata,
  }) {
    final result = Introduction._();
    if (fileMetadata != null) result.fileMetadata.addAll(fileMetadata);
    if (textMetadata != null) result.textMetadata.addAll(textMetadata);
    if (requiredPackage != null) result.requiredPackage = requiredPackage;
    if (wifiCredentialsMetadata != null)
      result.wifiCredentialsMetadata.addAll(wifiCredentialsMetadata);
    return result;
  }

  Introduction._();

  factory Introduction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Introduction()..mergeFromBuffer(data, registry);
  factory Introduction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Introduction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Introduction',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: Introduction.$_createMessage)
    ..pPM<FileMetadata>(1, _omitFieldNames ? '' : 'fileMetadata',
        subBuilder: FileMetadata.$_createMessage)
    ..pPM<TextMetadata>(2, _omitFieldNames ? '' : 'textMetadata',
        subBuilder: TextMetadata.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'requiredPackage')
    ..pPM<WifiCredentialsMetadata>(
        4, _omitFieldNames ? '' : 'wifiCredentialsMetadata',
        subBuilder: WifiCredentialsMetadata.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Introduction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Introduction copyWith(void Function(Introduction) updates) =>
      super.copyWith((message) => updates(message as Introduction))
          as Introduction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Introduction() / Introduction.new instead')
  static Introduction create() => Introduction._();
  static $pb.GeneratedMessage $_createMessage() => Introduction._();
  @$core.override
  Introduction createEmptyInstance() => Introduction._();
  @$core.pragma('dart2js:noInline')
  static Introduction getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Introduction>(
          Introduction.$_createMessage);
  static Introduction? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FileMetadata> get fileMetadata => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<TextMetadata> get textMetadata => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get requiredPackage => $_getSZ(2);
  @$pb.TagNumber(3)
  set requiredPackage($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequiredPackage() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequiredPackage() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<WifiCredentialsMetadata> get wifiCredentialsMetadata =>
      $_getList(3);
}

class TransferResponse extends $pb.GeneratedMessage {
  factory TransferResponse({
    TransferResponse_Status? status,
  }) {
    final result = TransferResponse._();
    if (status != null) result.status = status;
    return result;
  }

  TransferResponse._();

  factory TransferResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferResponse()..mergeFromBuffer(data, registry);
  factory TransferResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: TransferResponse.$_createMessage)
    ..aE<TransferResponse_Status>(1, _omitFieldNames ? '' : 'status',
        enumValues: TransferResponse_Status.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferResponse copyWith(void Function(TransferResponse) updates) =>
      super.copyWith((message) => updates(message as TransferResponse))
          as TransferResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferResponse() / TransferResponse.new instead')
  static TransferResponse create() => TransferResponse._();
  static $pb.GeneratedMessage $_createMessage() => TransferResponse._();
  @$core.override
  TransferResponse createEmptyInstance() => TransferResponse._();
  @$core.pragma('dart2js:noInline')
  static TransferResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransferResponse>(
          TransferResponse.$_createMessage);
  static TransferResponse? _defaultInstance;

  @$pb.TagNumber(1)
  TransferResponse_Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(TransferResponse_Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

/// Proves a shared Google account or contact. Ferret has neither, so it
/// sends random bytes, as other independent implementations do.
class PairedKeyEncryption extends $pb.GeneratedMessage {
  factory PairedKeyEncryption({
    $core.List<$core.int>? signedData,
    $core.List<$core.int>? secretIdHash,
    $core.List<$core.int>? optionalSignedData,
  }) {
    final result = PairedKeyEncryption._();
    if (signedData != null) result.signedData = signedData;
    if (secretIdHash != null) result.secretIdHash = secretIdHash;
    if (optionalSignedData != null)
      result.optionalSignedData = optionalSignedData;
    return result;
  }

  PairedKeyEncryption._();

  factory PairedKeyEncryption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairedKeyEncryption()..mergeFromBuffer(data, registry);
  factory PairedKeyEncryption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairedKeyEncryption()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairedKeyEncryption',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: PairedKeyEncryption.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'signedData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'secretIdHash', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'optionalSignedData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairedKeyEncryption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairedKeyEncryption copyWith(void Function(PairedKeyEncryption) updates) =>
      super.copyWith((message) => updates(message as PairedKeyEncryption))
          as PairedKeyEncryption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use PairedKeyEncryption() / PairedKeyEncryption.new instead')
  static PairedKeyEncryption create() => PairedKeyEncryption._();
  static $pb.GeneratedMessage $_createMessage() => PairedKeyEncryption._();
  @$core.override
  PairedKeyEncryption createEmptyInstance() => PairedKeyEncryption._();
  @$core.pragma('dart2js:noInline')
  static PairedKeyEncryption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PairedKeyEncryption>(
          PairedKeyEncryption.$_createMessage);
  static PairedKeyEncryption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get signedData => $_getN(0);
  @$pb.TagNumber(1)
  set signedData($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignedData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get secretIdHash => $_getN(1);
  @$pb.TagNumber(2)
  set secretIdHash($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSecretIdHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearSecretIdHash() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get optionalSignedData => $_getN(2);
  @$pb.TagNumber(3)
  set optionalSignedData($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOptionalSignedData() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptionalSignedData() => $_clearField(3);
}

class PairedKeyResult extends $pb.GeneratedMessage {
  factory PairedKeyResult({
    PairedKeyResult_Status? status,
  }) {
    final result = PairedKeyResult._();
    if (status != null) result.status = status;
    return result;
  }

  PairedKeyResult._();

  factory PairedKeyResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairedKeyResult()..mergeFromBuffer(data, registry);
  factory PairedKeyResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairedKeyResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairedKeyResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.sharing'),
      createEmptyInstance: PairedKeyResult.$_createMessage)
    ..aE<PairedKeyResult_Status>(1, _omitFieldNames ? '' : 'status',
        enumValues: PairedKeyResult_Status.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairedKeyResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairedKeyResult copyWith(void Function(PairedKeyResult) updates) =>
      super.copyWith((message) => updates(message as PairedKeyResult))
          as PairedKeyResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairedKeyResult() / PairedKeyResult.new instead')
  static PairedKeyResult create() => PairedKeyResult._();
  static $pb.GeneratedMessage $_createMessage() => PairedKeyResult._();
  @$core.override
  PairedKeyResult createEmptyInstance() => PairedKeyResult._();
  @$core.pragma('dart2js:noInline')
  static PairedKeyResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairedKeyResult>(
          PairedKeyResult.$_createMessage);
  static PairedKeyResult? _defaultInstance;

  @$pb.TagNumber(1)
  PairedKeyResult_Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(PairedKeyResult_Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
