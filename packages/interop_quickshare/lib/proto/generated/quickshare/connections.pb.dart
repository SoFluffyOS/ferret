// This is a generated file - do not edit.
//
// Generated from quickshare/connections.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'connections.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'connections.pbenum.dart';

class OfflineFrame extends $pb.GeneratedMessage {
  factory OfflineFrame({
    OfflineFrame_Version? version,
    OfflineFrameV1? v1,
  }) {
    final result = OfflineFrame._();
    if (version != null) result.version = version;
    if (v1 != null) result.v1 = v1;
    return result;
  }

  OfflineFrame._();

  factory OfflineFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OfflineFrame()..mergeFromBuffer(data, registry);
  factory OfflineFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OfflineFrame()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OfflineFrame',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: OfflineFrame.$_createMessage)
    ..aE<OfflineFrame_Version>(1, _omitFieldNames ? '' : 'version',
        enumValues: OfflineFrame_Version.values)
    ..aOM<OfflineFrameV1>(2, _omitFieldNames ? '' : 'v1',
        subBuilder: OfflineFrameV1.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfflineFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfflineFrame copyWith(void Function(OfflineFrame) updates) =>
      super.copyWith((message) => updates(message as OfflineFrame))
          as OfflineFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OfflineFrame() / OfflineFrame.new instead')
  static OfflineFrame create() => OfflineFrame._();
  static $pb.GeneratedMessage $_createMessage() => OfflineFrame._();
  @$core.override
  OfflineFrame createEmptyInstance() => OfflineFrame._();
  @$core.pragma('dart2js:noInline')
  static OfflineFrame getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OfflineFrame>(
          OfflineFrame.$_createMessage);
  static OfflineFrame? _defaultInstance;

  @$pb.TagNumber(1)
  OfflineFrame_Version get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(OfflineFrame_Version value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  OfflineFrameV1 get v1 => $_getN(1);
  @$pb.TagNumber(2)
  set v1(OfflineFrameV1 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasV1() => $_has(1);
  @$pb.TagNumber(2)
  void clearV1() => $_clearField(2);
  @$pb.TagNumber(2)
  OfflineFrameV1 ensureV1() => $_ensure(1);
}

class OfflineFrameV1 extends $pb.GeneratedMessage {
  factory OfflineFrameV1({
    OfflineFrameV1_FrameType? type,
    ConnectionRequest? connectionRequest,
    ConnectionResponse? connectionResponse,
    PayloadTransfer? payloadTransfer,
    KeepAlive? keepAlive,
    Disconnection? disconnection,
  }) {
    final result = OfflineFrameV1._();
    if (type != null) result.type = type;
    if (connectionRequest != null) result.connectionRequest = connectionRequest;
    if (connectionResponse != null)
      result.connectionResponse = connectionResponse;
    if (payloadTransfer != null) result.payloadTransfer = payloadTransfer;
    if (keepAlive != null) result.keepAlive = keepAlive;
    if (disconnection != null) result.disconnection = disconnection;
    return result;
  }

  OfflineFrameV1._();

  factory OfflineFrameV1.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OfflineFrameV1()..mergeFromBuffer(data, registry);
  factory OfflineFrameV1.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OfflineFrameV1()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OfflineFrameV1',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: OfflineFrameV1.$_createMessage)
    ..aE<OfflineFrameV1_FrameType>(1, _omitFieldNames ? '' : 'type',
        enumValues: OfflineFrameV1_FrameType.values)
    ..aOM<ConnectionRequest>(2, _omitFieldNames ? '' : 'connectionRequest',
        subBuilder: ConnectionRequest.$_createMessage)
    ..aOM<ConnectionResponse>(3, _omitFieldNames ? '' : 'connectionResponse',
        subBuilder: ConnectionResponse.$_createMessage)
    ..aOM<PayloadTransfer>(4, _omitFieldNames ? '' : 'payloadTransfer',
        subBuilder: PayloadTransfer.$_createMessage)
    ..aOM<KeepAlive>(6, _omitFieldNames ? '' : 'keepAlive',
        subBuilder: KeepAlive.$_createMessage)
    ..aOM<Disconnection>(7, _omitFieldNames ? '' : 'disconnection',
        subBuilder: Disconnection.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfflineFrameV1 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfflineFrameV1 copyWith(void Function(OfflineFrameV1) updates) =>
      super.copyWith((message) => updates(message as OfflineFrameV1))
          as OfflineFrameV1;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OfflineFrameV1() / OfflineFrameV1.new instead')
  static OfflineFrameV1 create() => OfflineFrameV1._();
  static $pb.GeneratedMessage $_createMessage() => OfflineFrameV1._();
  @$core.override
  OfflineFrameV1 createEmptyInstance() => OfflineFrameV1._();
  @$core.pragma('dart2js:noInline')
  static OfflineFrameV1 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OfflineFrameV1>(
          OfflineFrameV1.$_createMessage);
  static OfflineFrameV1? _defaultInstance;

  @$pb.TagNumber(1)
  OfflineFrameV1_FrameType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(OfflineFrameV1_FrameType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  ConnectionRequest get connectionRequest => $_getN(1);
  @$pb.TagNumber(2)
  set connectionRequest(ConnectionRequest value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectionRequest() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectionRequest() => $_clearField(2);
  @$pb.TagNumber(2)
  ConnectionRequest ensureConnectionRequest() => $_ensure(1);

  @$pb.TagNumber(3)
  ConnectionResponse get connectionResponse => $_getN(2);
  @$pb.TagNumber(3)
  set connectionResponse(ConnectionResponse value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConnectionResponse() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnectionResponse() => $_clearField(3);
  @$pb.TagNumber(3)
  ConnectionResponse ensureConnectionResponse() => $_ensure(2);

  @$pb.TagNumber(4)
  PayloadTransfer get payloadTransfer => $_getN(3);
  @$pb.TagNumber(4)
  set payloadTransfer(PayloadTransfer value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPayloadTransfer() => $_has(3);
  @$pb.TagNumber(4)
  void clearPayloadTransfer() => $_clearField(4);
  @$pb.TagNumber(4)
  PayloadTransfer ensurePayloadTransfer() => $_ensure(3);

  @$pb.TagNumber(6)
  KeepAlive get keepAlive => $_getN(4);
  @$pb.TagNumber(6)
  set keepAlive(KeepAlive value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasKeepAlive() => $_has(4);
  @$pb.TagNumber(6)
  void clearKeepAlive() => $_clearField(6);
  @$pb.TagNumber(6)
  KeepAlive ensureKeepAlive() => $_ensure(4);

  @$pb.TagNumber(7)
  Disconnection get disconnection => $_getN(5);
  @$pb.TagNumber(7)
  set disconnection(Disconnection value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDisconnection() => $_has(5);
  @$pb.TagNumber(7)
  void clearDisconnection() => $_clearField(7);
  @$pb.TagNumber(7)
  Disconnection ensureDisconnection() => $_ensure(5);
}

class ConnectionRequest extends $pb.GeneratedMessage {
  factory ConnectionRequest({
    $core.String? endpointId,
    $core.String? endpointName,
    $core.int? nonce,
    $core.Iterable<ConnectionRequest_Medium>? mediums,
    $core.List<$core.int>? endpointInfo,
    $core.int? keepAliveIntervalMillis,
    $core.int? keepAliveTimeoutMillis,
  }) {
    final result = ConnectionRequest._();
    if (endpointId != null) result.endpointId = endpointId;
    if (endpointName != null) result.endpointName = endpointName;
    if (nonce != null) result.nonce = nonce;
    if (mediums != null) result.mediums.addAll(mediums);
    if (endpointInfo != null) result.endpointInfo = endpointInfo;
    if (keepAliveIntervalMillis != null)
      result.keepAliveIntervalMillis = keepAliveIntervalMillis;
    if (keepAliveTimeoutMillis != null)
      result.keepAliveTimeoutMillis = keepAliveTimeoutMillis;
    return result;
  }

  ConnectionRequest._();

  factory ConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionRequest()..mergeFromBuffer(data, registry);
  factory ConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: ConnectionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'endpointId')
    ..aOS(2, _omitFieldNames ? '' : 'endpointName')
    ..aI(4, _omitFieldNames ? '' : 'nonce')
    ..pPE<ConnectionRequest_Medium>(5, _omitFieldNames ? '' : 'mediums',
        enumValues: ConnectionRequest_Medium.values)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'endpointInfo', $pb.PbFieldType.OY)
    ..aI(8, _omitFieldNames ? '' : 'keepAliveIntervalMillis')
    ..aI(9, _omitFieldNames ? '' : 'keepAliveTimeoutMillis')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionRequest copyWith(void Function(ConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectionRequest))
          as ConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectionRequest() / ConnectionRequest.new instead')
  static ConnectionRequest create() => ConnectionRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectionRequest._();
  @$core.override
  ConnectionRequest createEmptyInstance() => ConnectionRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectionRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectionRequest>(
          ConnectionRequest.$_createMessage);
  static ConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get endpointId => $_getSZ(0);
  @$pb.TagNumber(1)
  set endpointId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEndpointId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEndpointId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get endpointName => $_getSZ(1);
  @$pb.TagNumber(2)
  set endpointName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndpointName() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndpointName() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.int get nonce => $_getIZ(2);
  @$pb.TagNumber(4)
  set nonce($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(4)
  $core.bool hasNonce() => $_has(2);
  @$pb.TagNumber(4)
  void clearNonce() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<ConnectionRequest_Medium> get mediums => $_getList(3);

  /// Device kind and name, in the same layout as the mDNS TXT record.
  @$pb.TagNumber(6)
  $core.List<$core.int> get endpointInfo => $_getN(4);
  @$pb.TagNumber(6)
  set endpointInfo($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(6)
  $core.bool hasEndpointInfo() => $_has(4);
  @$pb.TagNumber(6)
  void clearEndpointInfo() => $_clearField(6);

  @$pb.TagNumber(8)
  $core.int get keepAliveIntervalMillis => $_getIZ(5);
  @$pb.TagNumber(8)
  set keepAliveIntervalMillis($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(8)
  $core.bool hasKeepAliveIntervalMillis() => $_has(5);
  @$pb.TagNumber(8)
  void clearKeepAliveIntervalMillis() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get keepAliveTimeoutMillis => $_getIZ(6);
  @$pb.TagNumber(9)
  set keepAliveTimeoutMillis($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(9)
  $core.bool hasKeepAliveTimeoutMillis() => $_has(6);
  @$pb.TagNumber(9)
  void clearKeepAliveTimeoutMillis() => $_clearField(9);
}

class ConnectionResponse extends $pb.GeneratedMessage {
  factory ConnectionResponse({
    $core.int? status,
    ConnectionResponse_ResponseStatus? response,
    OsInfo? osInfo,
  }) {
    final result = ConnectionResponse._();
    if (status != null) result.status = status;
    if (response != null) result.response = response;
    if (osInfo != null) result.osInfo = osInfo;
    return result;
  }

  ConnectionResponse._();

  factory ConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionResponse()..mergeFromBuffer(data, registry);
  factory ConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: ConnectionResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'status')
    ..aE<ConnectionResponse_ResponseStatus>(
        3, _omitFieldNames ? '' : 'response',
        enumValues: ConnectionResponse_ResponseStatus.values)
    ..aOM<OsInfo>(4, _omitFieldNames ? '' : 'osInfo',
        subBuilder: OsInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionResponse copyWith(void Function(ConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as ConnectionResponse))
          as ConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectionResponse() / ConnectionResponse.new instead')
  static ConnectionResponse create() => ConnectionResponse._();
  static $pb.GeneratedMessage $_createMessage() => ConnectionResponse._();
  @$core.override
  ConnectionResponse createEmptyInstance() => ConnectionResponse._();
  @$core.pragma('dart2js:noInline')
  static ConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionResponse>(
          ConnectionResponse.$_createMessage);
  static ConnectionResponse? _defaultInstance;

  /// The older way to answer: 0 accepts.
  @$pb.TagNumber(1)
  $core.int get status => $_getIZ(0);
  @$pb.TagNumber(1)
  set status($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(3)
  ConnectionResponse_ResponseStatus get response => $_getN(1);
  @$pb.TagNumber(3)
  set response(ConnectionResponse_ResponseStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResponse() => $_has(1);
  @$pb.TagNumber(3)
  void clearResponse() => $_clearField(3);

  @$pb.TagNumber(4)
  OsInfo get osInfo => $_getN(2);
  @$pb.TagNumber(4)
  set osInfo(OsInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOsInfo() => $_has(2);
  @$pb.TagNumber(4)
  void clearOsInfo() => $_clearField(4);
  @$pb.TagNumber(4)
  OsInfo ensureOsInfo() => $_ensure(2);
}

class OsInfo extends $pb.GeneratedMessage {
  factory OsInfo({
    OsInfo_OsType? type,
  }) {
    final result = OsInfo._();
    if (type != null) result.type = type;
    return result;
  }

  OsInfo._();

  factory OsInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OsInfo()..mergeFromBuffer(data, registry);
  factory OsInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OsInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OsInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: OsInfo.$_createMessage)
    ..aE<OsInfo_OsType>(1, _omitFieldNames ? '' : 'type',
        enumValues: OsInfo_OsType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OsInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OsInfo copyWith(void Function(OsInfo) updates) =>
      super.copyWith((message) => updates(message as OsInfo)) as OsInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OsInfo() / OsInfo.new instead')
  static OsInfo create() => OsInfo._();
  static $pb.GeneratedMessage $_createMessage() => OsInfo._();
  @$core.override
  OsInfo createEmptyInstance() => OsInfo._();
  @$core.pragma('dart2js:noInline')
  static OsInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OsInfo>(OsInfo.$_createMessage);
  static OsInfo? _defaultInstance;

  @$pb.TagNumber(1)
  OsInfo_OsType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(OsInfo_OsType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

class PayloadTransfer_PayloadHeader extends $pb.GeneratedMessage {
  factory PayloadTransfer_PayloadHeader({
    $fixnum.Int64? id,
    PayloadTransfer_PayloadHeader_PayloadType? type,
    $fixnum.Int64? totalSize,
    $core.bool? isSensitive,
    $core.String? fileName,
    $core.String? parentFolder,
  }) {
    final result = PayloadTransfer_PayloadHeader._();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (totalSize != null) result.totalSize = totalSize;
    if (isSensitive != null) result.isSensitive = isSensitive;
    if (fileName != null) result.fileName = fileName;
    if (parentFolder != null) result.parentFolder = parentFolder;
    return result;
  }

  PayloadTransfer_PayloadHeader._();

  factory PayloadTransfer_PayloadHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer_PayloadHeader()..mergeFromBuffer(data, registry);
  factory PayloadTransfer_PayloadHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer_PayloadHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PayloadTransfer.PayloadHeader',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: PayloadTransfer_PayloadHeader.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aE<PayloadTransfer_PayloadHeader_PayloadType>(
        2, _omitFieldNames ? '' : 'type',
        enumValues: PayloadTransfer_PayloadHeader_PayloadType.values)
    ..aInt64(3, _omitFieldNames ? '' : 'totalSize')
    ..aOB(4, _omitFieldNames ? '' : 'isSensitive')
    ..aOS(5, _omitFieldNames ? '' : 'fileName')
    ..aOS(6, _omitFieldNames ? '' : 'parentFolder')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer_PayloadHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer_PayloadHeader copyWith(
          void Function(PayloadTransfer_PayloadHeader) updates) =>
      super.copyWith(
              (message) => updates(message as PayloadTransfer_PayloadHeader))
          as PayloadTransfer_PayloadHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PayloadTransfer_PayloadHeader() / PayloadTransfer_PayloadHeader.new instead')
  static PayloadTransfer_PayloadHeader create() =>
      PayloadTransfer_PayloadHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      PayloadTransfer_PayloadHeader._();
  @$core.override
  PayloadTransfer_PayloadHeader createEmptyInstance() =>
      PayloadTransfer_PayloadHeader._();
  @$core.pragma('dart2js:noInline')
  static PayloadTransfer_PayloadHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PayloadTransfer_PayloadHeader>(
          PayloadTransfer_PayloadHeader.$_createMessage);
  static PayloadTransfer_PayloadHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  PayloadTransfer_PayloadHeader_PayloadType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(PayloadTransfer_PayloadHeader_PayloadType value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get totalSize => $_getI64(2);
  @$pb.TagNumber(3)
  set totalSize($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalSize() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isSensitive => $_getBF(3);
  @$pb.TagNumber(4)
  set isSensitive($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsSensitive() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsSensitive() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get fileName => $_getSZ(4);
  @$pb.TagNumber(5)
  set fileName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFileName() => $_has(4);
  @$pb.TagNumber(5)
  void clearFileName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get parentFolder => $_getSZ(5);
  @$pb.TagNumber(6)
  set parentFolder($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasParentFolder() => $_has(5);
  @$pb.TagNumber(6)
  void clearParentFolder() => $_clearField(6);
}

class PayloadTransfer_PayloadChunk extends $pb.GeneratedMessage {
  factory PayloadTransfer_PayloadChunk({
    $core.int? flags,
    $fixnum.Int64? offset,
    $core.List<$core.int>? body,
  }) {
    final result = PayloadTransfer_PayloadChunk._();
    if (flags != null) result.flags = flags;
    if (offset != null) result.offset = offset;
    if (body != null) result.body = body;
    return result;
  }

  PayloadTransfer_PayloadChunk._();

  factory PayloadTransfer_PayloadChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer_PayloadChunk()..mergeFromBuffer(data, registry);
  factory PayloadTransfer_PayloadChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer_PayloadChunk()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PayloadTransfer.PayloadChunk',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: PayloadTransfer_PayloadChunk.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'flags')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer_PayloadChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer_PayloadChunk copyWith(
          void Function(PayloadTransfer_PayloadChunk) updates) =>
      super.copyWith(
              (message) => updates(message as PayloadTransfer_PayloadChunk))
          as PayloadTransfer_PayloadChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PayloadTransfer_PayloadChunk() / PayloadTransfer_PayloadChunk.new instead')
  static PayloadTransfer_PayloadChunk create() =>
      PayloadTransfer_PayloadChunk._();
  static $pb.GeneratedMessage $_createMessage() =>
      PayloadTransfer_PayloadChunk._();
  @$core.override
  PayloadTransfer_PayloadChunk createEmptyInstance() =>
      PayloadTransfer_PayloadChunk._();
  @$core.pragma('dart2js:noInline')
  static PayloadTransfer_PayloadChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PayloadTransfer_PayloadChunk>(
          PayloadTransfer_PayloadChunk.$_createMessage);
  static PayloadTransfer_PayloadChunk? _defaultInstance;

  /// Bit 0 of flags marks the last chunk of a payload.
  @$pb.TagNumber(1)
  $core.int get flags => $_getIZ(0);
  @$pb.TagNumber(1)
  set flags($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFlags() => $_has(0);
  @$pb.TagNumber(1)
  void clearFlags() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get body => $_getN(2);
  @$pb.TagNumber(3)
  set body($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBody() => $_has(2);
  @$pb.TagNumber(3)
  void clearBody() => $_clearField(3);
}

class PayloadTransfer_ControlMessage extends $pb.GeneratedMessage {
  factory PayloadTransfer_ControlMessage({
    PayloadTransfer_ControlMessage_EventType? event,
    $fixnum.Int64? offset,
  }) {
    final result = PayloadTransfer_ControlMessage._();
    if (event != null) result.event = event;
    if (offset != null) result.offset = offset;
    return result;
  }

  PayloadTransfer_ControlMessage._();

  factory PayloadTransfer_ControlMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer_ControlMessage()..mergeFromBuffer(data, registry);
  factory PayloadTransfer_ControlMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer_ControlMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PayloadTransfer.ControlMessage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: PayloadTransfer_ControlMessage.$_createMessage)
    ..aE<PayloadTransfer_ControlMessage_EventType>(
        1, _omitFieldNames ? '' : 'event',
        enumValues: PayloadTransfer_ControlMessage_EventType.values)
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer_ControlMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer_ControlMessage copyWith(
          void Function(PayloadTransfer_ControlMessage) updates) =>
      super.copyWith(
              (message) => updates(message as PayloadTransfer_ControlMessage))
          as PayloadTransfer_ControlMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PayloadTransfer_ControlMessage() / PayloadTransfer_ControlMessage.new instead')
  static PayloadTransfer_ControlMessage create() =>
      PayloadTransfer_ControlMessage._();
  static $pb.GeneratedMessage $_createMessage() =>
      PayloadTransfer_ControlMessage._();
  @$core.override
  PayloadTransfer_ControlMessage createEmptyInstance() =>
      PayloadTransfer_ControlMessage._();
  @$core.pragma('dart2js:noInline')
  static PayloadTransfer_ControlMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PayloadTransfer_ControlMessage>(
          PayloadTransfer_ControlMessage.$_createMessage);
  static PayloadTransfer_ControlMessage? _defaultInstance;

  @$pb.TagNumber(1)
  PayloadTransfer_ControlMessage_EventType get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(PayloadTransfer_ControlMessage_EventType value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

class PayloadTransfer extends $pb.GeneratedMessage {
  factory PayloadTransfer({
    PayloadTransfer_PacketType? packetType,
    PayloadTransfer_PayloadHeader? payloadHeader,
    PayloadTransfer_PayloadChunk? payloadChunk,
    PayloadTransfer_ControlMessage? controlMessage,
  }) {
    final result = PayloadTransfer._();
    if (packetType != null) result.packetType = packetType;
    if (payloadHeader != null) result.payloadHeader = payloadHeader;
    if (payloadChunk != null) result.payloadChunk = payloadChunk;
    if (controlMessage != null) result.controlMessage = controlMessage;
    return result;
  }

  PayloadTransfer._();

  factory PayloadTransfer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer()..mergeFromBuffer(data, registry);
  factory PayloadTransfer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PayloadTransfer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PayloadTransfer',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: PayloadTransfer.$_createMessage)
    ..aE<PayloadTransfer_PacketType>(1, _omitFieldNames ? '' : 'packetType',
        enumValues: PayloadTransfer_PacketType.values)
    ..aOM<PayloadTransfer_PayloadHeader>(
        2, _omitFieldNames ? '' : 'payloadHeader',
        subBuilder: PayloadTransfer_PayloadHeader.$_createMessage)
    ..aOM<PayloadTransfer_PayloadChunk>(
        3, _omitFieldNames ? '' : 'payloadChunk',
        subBuilder: PayloadTransfer_PayloadChunk.$_createMessage)
    ..aOM<PayloadTransfer_ControlMessage>(
        4, _omitFieldNames ? '' : 'controlMessage',
        subBuilder: PayloadTransfer_ControlMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PayloadTransfer copyWith(void Function(PayloadTransfer) updates) =>
      super.copyWith((message) => updates(message as PayloadTransfer))
          as PayloadTransfer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PayloadTransfer() / PayloadTransfer.new instead')
  static PayloadTransfer create() => PayloadTransfer._();
  static $pb.GeneratedMessage $_createMessage() => PayloadTransfer._();
  @$core.override
  PayloadTransfer createEmptyInstance() => PayloadTransfer._();
  @$core.pragma('dart2js:noInline')
  static PayloadTransfer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PayloadTransfer>(
          PayloadTransfer.$_createMessage);
  static PayloadTransfer? _defaultInstance;

  @$pb.TagNumber(1)
  PayloadTransfer_PacketType get packetType => $_getN(0);
  @$pb.TagNumber(1)
  set packetType(PayloadTransfer_PacketType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPacketType() => $_has(0);
  @$pb.TagNumber(1)
  void clearPacketType() => $_clearField(1);

  @$pb.TagNumber(2)
  PayloadTransfer_PayloadHeader get payloadHeader => $_getN(1);
  @$pb.TagNumber(2)
  set payloadHeader(PayloadTransfer_PayloadHeader value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPayloadHeader() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayloadHeader() => $_clearField(2);
  @$pb.TagNumber(2)
  PayloadTransfer_PayloadHeader ensurePayloadHeader() => $_ensure(1);

  @$pb.TagNumber(3)
  PayloadTransfer_PayloadChunk get payloadChunk => $_getN(2);
  @$pb.TagNumber(3)
  set payloadChunk(PayloadTransfer_PayloadChunk value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPayloadChunk() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayloadChunk() => $_clearField(3);
  @$pb.TagNumber(3)
  PayloadTransfer_PayloadChunk ensurePayloadChunk() => $_ensure(2);

  @$pb.TagNumber(4)
  PayloadTransfer_ControlMessage get controlMessage => $_getN(3);
  @$pb.TagNumber(4)
  set controlMessage(PayloadTransfer_ControlMessage value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasControlMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearControlMessage() => $_clearField(4);
  @$pb.TagNumber(4)
  PayloadTransfer_ControlMessage ensureControlMessage() => $_ensure(3);
}

class KeepAlive extends $pb.GeneratedMessage {
  factory KeepAlive({
    $core.bool? ack,
  }) {
    final result = KeepAlive._();
    if (ack != null) result.ack = ack;
    return result;
  }

  KeepAlive._();

  factory KeepAlive.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeepAlive()..mergeFromBuffer(data, registry);
  factory KeepAlive.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeepAlive()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeepAlive',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: KeepAlive.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ack')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeepAlive clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeepAlive copyWith(void Function(KeepAlive) updates) =>
      super.copyWith((message) => updates(message as KeepAlive)) as KeepAlive;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KeepAlive() / KeepAlive.new instead')
  static KeepAlive create() => KeepAlive._();
  static $pb.GeneratedMessage $_createMessage() => KeepAlive._();
  @$core.override
  KeepAlive createEmptyInstance() => KeepAlive._();
  @$core.pragma('dart2js:noInline')
  static KeepAlive getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeepAlive>(KeepAlive.$_createMessage);
  static KeepAlive? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ack => $_getBF(0);
  @$pb.TagNumber(1)
  set ack($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAck() => $_has(0);
  @$pb.TagNumber(1)
  void clearAck() => $_clearField(1);
}

class Disconnection extends $pb.GeneratedMessage {
  factory Disconnection({
    $core.bool? requestSafeToDisconnect,
    $core.bool? ackSafeToDisconnect,
  }) {
    final result = Disconnection._();
    if (requestSafeToDisconnect != null)
      result.requestSafeToDisconnect = requestSafeToDisconnect;
    if (ackSafeToDisconnect != null)
      result.ackSafeToDisconnect = ackSafeToDisconnect;
    return result;
  }

  Disconnection._();

  factory Disconnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Disconnection()..mergeFromBuffer(data, registry);
  factory Disconnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Disconnection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Disconnection',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.connections'),
      createEmptyInstance: Disconnection.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'requestSafeToDisconnect')
    ..aOB(2, _omitFieldNames ? '' : 'ackSafeToDisconnect')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Disconnection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Disconnection copyWith(void Function(Disconnection) updates) =>
      super.copyWith((message) => updates(message as Disconnection))
          as Disconnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Disconnection() / Disconnection.new instead')
  static Disconnection create() => Disconnection._();
  static $pb.GeneratedMessage $_createMessage() => Disconnection._();
  @$core.override
  Disconnection createEmptyInstance() => Disconnection._();
  @$core.pragma('dart2js:noInline')
  static Disconnection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Disconnection>(
          Disconnection.$_createMessage);
  static Disconnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get requestSafeToDisconnect => $_getBF(0);
  @$pb.TagNumber(1)
  set requestSafeToDisconnect($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestSafeToDisconnect() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestSafeToDisconnect() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ackSafeToDisconnect => $_getBF(1);
  @$pb.TagNumber(2)
  set ackSafeToDisconnect($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAckSafeToDisconnect() => $_has(1);
  @$pb.TagNumber(2)
  void clearAckSafeToDisconnect() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
