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

import 'package:protobuf/protobuf.dart' as $pb;

class OfflineFrame_Version extends $pb.ProtobufEnum {
  static const OfflineFrame_Version UNKNOWN_VERSION =
      OfflineFrame_Version._(0, _omitEnumNames ? '' : 'UNKNOWN_VERSION');
  static const OfflineFrame_Version V1 =
      OfflineFrame_Version._(1, _omitEnumNames ? '' : 'V1');

  static const $core.List<OfflineFrame_Version> values = <OfflineFrame_Version>[
    UNKNOWN_VERSION,
    V1,
  ];

  static final $core.List<OfflineFrame_Version?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static OfflineFrame_Version? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OfflineFrame_Version._(super.value, super.name);
}

class OfflineFrameV1_FrameType extends $pb.ProtobufEnum {
  static const OfflineFrameV1_FrameType UNKNOWN_FRAME_TYPE =
      OfflineFrameV1_FrameType._(0, _omitEnumNames ? '' : 'UNKNOWN_FRAME_TYPE');
  static const OfflineFrameV1_FrameType CONNECTION_REQUEST =
      OfflineFrameV1_FrameType._(1, _omitEnumNames ? '' : 'CONNECTION_REQUEST');
  static const OfflineFrameV1_FrameType CONNECTION_RESPONSE =
      OfflineFrameV1_FrameType._(
          2, _omitEnumNames ? '' : 'CONNECTION_RESPONSE');
  static const OfflineFrameV1_FrameType PAYLOAD_TRANSFER =
      OfflineFrameV1_FrameType._(3, _omitEnumNames ? '' : 'PAYLOAD_TRANSFER');
  static const OfflineFrameV1_FrameType BANDWIDTH_UPGRADE_NEGOTIATION =
      OfflineFrameV1_FrameType._(
          4, _omitEnumNames ? '' : 'BANDWIDTH_UPGRADE_NEGOTIATION');
  static const OfflineFrameV1_FrameType KEEP_ALIVE =
      OfflineFrameV1_FrameType._(5, _omitEnumNames ? '' : 'KEEP_ALIVE');
  static const OfflineFrameV1_FrameType DISCONNECTION =
      OfflineFrameV1_FrameType._(6, _omitEnumNames ? '' : 'DISCONNECTION');
  static const OfflineFrameV1_FrameType PAIRED_KEY_ENCRYPTION =
      OfflineFrameV1_FrameType._(
          7, _omitEnumNames ? '' : 'PAIRED_KEY_ENCRYPTION');

  static const $core.List<OfflineFrameV1_FrameType> values =
      <OfflineFrameV1_FrameType>[
    UNKNOWN_FRAME_TYPE,
    CONNECTION_REQUEST,
    CONNECTION_RESPONSE,
    PAYLOAD_TRANSFER,
    BANDWIDTH_UPGRADE_NEGOTIATION,
    KEEP_ALIVE,
    DISCONNECTION,
    PAIRED_KEY_ENCRYPTION,
  ];

  static final $core.List<OfflineFrameV1_FrameType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static OfflineFrameV1_FrameType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OfflineFrameV1_FrameType._(super.value, super.name);
}

class ConnectionRequest_Medium extends $pb.ProtobufEnum {
  static const ConnectionRequest_Medium UNKNOWN_MEDIUM =
      ConnectionRequest_Medium._(0, _omitEnumNames ? '' : 'UNKNOWN_MEDIUM');
  static const ConnectionRequest_Medium MDNS =
      ConnectionRequest_Medium._(1, _omitEnumNames ? '' : 'MDNS');
  static const ConnectionRequest_Medium BLUETOOTH =
      ConnectionRequest_Medium._(2, _omitEnumNames ? '' : 'BLUETOOTH');
  static const ConnectionRequest_Medium WIFI_HOTSPOT =
      ConnectionRequest_Medium._(3, _omitEnumNames ? '' : 'WIFI_HOTSPOT');
  static const ConnectionRequest_Medium BLE =
      ConnectionRequest_Medium._(4, _omitEnumNames ? '' : 'BLE');
  static const ConnectionRequest_Medium WIFI_LAN =
      ConnectionRequest_Medium._(5, _omitEnumNames ? '' : 'WIFI_LAN');
  static const ConnectionRequest_Medium WIFI_AWARE =
      ConnectionRequest_Medium._(6, _omitEnumNames ? '' : 'WIFI_AWARE');
  static const ConnectionRequest_Medium NFC =
      ConnectionRequest_Medium._(7, _omitEnumNames ? '' : 'NFC');
  static const ConnectionRequest_Medium WIFI_DIRECT =
      ConnectionRequest_Medium._(8, _omitEnumNames ? '' : 'WIFI_DIRECT');
  static const ConnectionRequest_Medium WEB_RTC =
      ConnectionRequest_Medium._(9, _omitEnumNames ? '' : 'WEB_RTC');
  static const ConnectionRequest_Medium BLE_L2CAP =
      ConnectionRequest_Medium._(10, _omitEnumNames ? '' : 'BLE_L2CAP');
  static const ConnectionRequest_Medium USB =
      ConnectionRequest_Medium._(11, _omitEnumNames ? '' : 'USB');

  static const $core.List<ConnectionRequest_Medium> values =
      <ConnectionRequest_Medium>[
    UNKNOWN_MEDIUM,
    MDNS,
    BLUETOOTH,
    WIFI_HOTSPOT,
    BLE,
    WIFI_LAN,
    WIFI_AWARE,
    NFC,
    WIFI_DIRECT,
    WEB_RTC,
    BLE_L2CAP,
    USB,
  ];

  static final $core.List<ConnectionRequest_Medium?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static ConnectionRequest_Medium? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConnectionRequest_Medium._(super.value, super.name);
}

class ConnectionResponse_ResponseStatus extends $pb.ProtobufEnum {
  static const ConnectionResponse_ResponseStatus UNKNOWN_RESPONSE_STATUS =
      ConnectionResponse_ResponseStatus._(
          0, _omitEnumNames ? '' : 'UNKNOWN_RESPONSE_STATUS');
  static const ConnectionResponse_ResponseStatus ACCEPT =
      ConnectionResponse_ResponseStatus._(1, _omitEnumNames ? '' : 'ACCEPT');
  static const ConnectionResponse_ResponseStatus REJECT =
      ConnectionResponse_ResponseStatus._(2, _omitEnumNames ? '' : 'REJECT');

  static const $core.List<ConnectionResponse_ResponseStatus> values =
      <ConnectionResponse_ResponseStatus>[
    UNKNOWN_RESPONSE_STATUS,
    ACCEPT,
    REJECT,
  ];

  static final $core.List<ConnectionResponse_ResponseStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ConnectionResponse_ResponseStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConnectionResponse_ResponseStatus._(super.value, super.name);
}

class OsInfo_OsType extends $pb.ProtobufEnum {
  static const OsInfo_OsType UNKNOWN_OS_TYPE =
      OsInfo_OsType._(0, _omitEnumNames ? '' : 'UNKNOWN_OS_TYPE');
  static const OsInfo_OsType ANDROID =
      OsInfo_OsType._(1, _omitEnumNames ? '' : 'ANDROID');
  static const OsInfo_OsType CHROME_OS =
      OsInfo_OsType._(2, _omitEnumNames ? '' : 'CHROME_OS');
  static const OsInfo_OsType WINDOWS =
      OsInfo_OsType._(3, _omitEnumNames ? '' : 'WINDOWS');
  static const OsInfo_OsType APPLE =
      OsInfo_OsType._(4, _omitEnumNames ? '' : 'APPLE');
  static const OsInfo_OsType LINUX =
      OsInfo_OsType._(100, _omitEnumNames ? '' : 'LINUX');

  static const $core.List<OsInfo_OsType> values = <OsInfo_OsType>[
    UNKNOWN_OS_TYPE,
    ANDROID,
    CHROME_OS,
    WINDOWS,
    APPLE,
    LINUX,
  ];

  static final $core.Map<$core.int, OsInfo_OsType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static OsInfo_OsType? valueOf($core.int value) => _byValue[value];

  const OsInfo_OsType._(super.value, super.name);
}

class PayloadTransfer_PacketType extends $pb.ProtobufEnum {
  static const PayloadTransfer_PacketType UNKNOWN_PACKET_TYPE =
      PayloadTransfer_PacketType._(
          0, _omitEnumNames ? '' : 'UNKNOWN_PACKET_TYPE');
  static const PayloadTransfer_PacketType DATA =
      PayloadTransfer_PacketType._(1, _omitEnumNames ? '' : 'DATA');
  static const PayloadTransfer_PacketType CONTROL =
      PayloadTransfer_PacketType._(2, _omitEnumNames ? '' : 'CONTROL');
  static const PayloadTransfer_PacketType PAYLOAD_ACK =
      PayloadTransfer_PacketType._(3, _omitEnumNames ? '' : 'PAYLOAD_ACK');

  static const $core.List<PayloadTransfer_PacketType> values =
      <PayloadTransfer_PacketType>[
    UNKNOWN_PACKET_TYPE,
    DATA,
    CONTROL,
    PAYLOAD_ACK,
  ];

  static final $core.List<PayloadTransfer_PacketType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PayloadTransfer_PacketType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PayloadTransfer_PacketType._(super.value, super.name);
}

class PayloadTransfer_PayloadHeader_PayloadType extends $pb.ProtobufEnum {
  static const PayloadTransfer_PayloadHeader_PayloadType UNKNOWN_PAYLOAD_TYPE =
      PayloadTransfer_PayloadHeader_PayloadType._(
          0, _omitEnumNames ? '' : 'UNKNOWN_PAYLOAD_TYPE');
  static const PayloadTransfer_PayloadHeader_PayloadType BYTES =
      PayloadTransfer_PayloadHeader_PayloadType._(
          1, _omitEnumNames ? '' : 'BYTES');
  static const PayloadTransfer_PayloadHeader_PayloadType FILE =
      PayloadTransfer_PayloadHeader_PayloadType._(
          2, _omitEnumNames ? '' : 'FILE');
  static const PayloadTransfer_PayloadHeader_PayloadType STREAM =
      PayloadTransfer_PayloadHeader_PayloadType._(
          3, _omitEnumNames ? '' : 'STREAM');

  static const $core.List<PayloadTransfer_PayloadHeader_PayloadType> values =
      <PayloadTransfer_PayloadHeader_PayloadType>[
    UNKNOWN_PAYLOAD_TYPE,
    BYTES,
    FILE,
    STREAM,
  ];

  static final $core.List<PayloadTransfer_PayloadHeader_PayloadType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PayloadTransfer_PayloadHeader_PayloadType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PayloadTransfer_PayloadHeader_PayloadType._(super.value, super.name);
}

class PayloadTransfer_ControlMessage_EventType extends $pb.ProtobufEnum {
  static const PayloadTransfer_ControlMessage_EventType UNKNOWN_EVENT_TYPE =
      PayloadTransfer_ControlMessage_EventType._(
          0, _omitEnumNames ? '' : 'UNKNOWN_EVENT_TYPE');
  static const PayloadTransfer_ControlMessage_EventType PAYLOAD_ERROR =
      PayloadTransfer_ControlMessage_EventType._(
          1, _omitEnumNames ? '' : 'PAYLOAD_ERROR');
  static const PayloadTransfer_ControlMessage_EventType PAYLOAD_CANCELED =
      PayloadTransfer_ControlMessage_EventType._(
          2, _omitEnumNames ? '' : 'PAYLOAD_CANCELED');
  static const PayloadTransfer_ControlMessage_EventType PAYLOAD_RECEIVED_ACK =
      PayloadTransfer_ControlMessage_EventType._(
          3, _omitEnumNames ? '' : 'PAYLOAD_RECEIVED_ACK');

  static const $core.List<PayloadTransfer_ControlMessage_EventType> values =
      <PayloadTransfer_ControlMessage_EventType>[
    UNKNOWN_EVENT_TYPE,
    PAYLOAD_ERROR,
    PAYLOAD_CANCELED,
    PAYLOAD_RECEIVED_ACK,
  ];

  static final $core.List<PayloadTransfer_ControlMessage_EventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PayloadTransfer_ControlMessage_EventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PayloadTransfer_ControlMessage_EventType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
