// This is a generated file - do not edit.
//
// Generated from ferret/v1/wake.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// How a network card is connected. Wired cards wake reliably once
/// Wake-on-LAN is on; few Wi-Fi cards wake at all.
class WakeLink extends $pb.ProtobufEnum {
  static const WakeLink WAKE_LINK_UNSPECIFIED =
      WakeLink._(0, _omitEnumNames ? '' : 'WAKE_LINK_UNSPECIFIED');
  static const WakeLink WAKE_LINK_WIRED =
      WakeLink._(1, _omitEnumNames ? '' : 'WAKE_LINK_WIRED');
  static const WakeLink WAKE_LINK_WIFI =
      WakeLink._(2, _omitEnumNames ? '' : 'WAKE_LINK_WIFI');

  static const $core.List<WakeLink> values = <WakeLink>[
    WAKE_LINK_UNSPECIFIED,
    WAKE_LINK_WIRED,
    WAKE_LINK_WIFI,
  ];

  static final $core.List<WakeLink?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static WakeLink? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WakeLink._(super.value, super.name);
}

/// What the computer's own settings say about waking on a magic packet.
class WakeSetting extends $pb.ProtobufEnum {
  /// It couldn't tell, such as without permission to ask the driver.
  static const WakeSetting WAKE_SETTING_UNSPECIFIED =
      WakeSetting._(0, _omitEnumNames ? '' : 'WAKE_SETTING_UNSPECIFIED');
  static const WakeSetting WAKE_SETTING_ON =
      WakeSetting._(1, _omitEnumNames ? '' : 'WAKE_SETTING_ON');
  static const WakeSetting WAKE_SETTING_OFF =
      WakeSetting._(2, _omitEnumNames ? '' : 'WAKE_SETTING_OFF');

  static const $core.List<WakeSetting> values = <WakeSetting>[
    WAKE_SETTING_UNSPECIFIED,
    WAKE_SETTING_ON,
    WAKE_SETTING_OFF,
  ];

  static final $core.List<WakeSetting?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static WakeSetting? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WakeSetting._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
