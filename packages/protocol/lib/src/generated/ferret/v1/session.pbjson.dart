// This is a generated file - do not edit.
//
// Generated from ferret/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use goodbyeReasonDescriptor instead')
const GoodbyeReason$json = {
  '1': 'GoodbyeReason',
  '2': [
    {'1': 'GOODBYE_REASON_UNSPECIFIED', '2': 0},
    {'1': 'GOODBYE_REASON_SHUTDOWN', '2': 1},
    {'1': 'GOODBYE_REASON_UNPAIRED', '2': 2},
    {'1': 'GOODBYE_REASON_DUPLICATE', '2': 3},
  ],
};

/// Descriptor for `GoodbyeReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List goodbyeReasonDescriptor = $convert.base64Decode(
    'Cg1Hb29kYnllUmVhc29uEh4KGkdPT0RCWUVfUkVBU09OX1VOU1BFQ0lGSUVEEAASGwoXR09PRE'
    'JZRV9SRUFTT05fU0hVVERPV04QARIbChdHT09EQllFX1JFQVNPTl9VTlBBSVJFRBACEhwKGEdP'
    'T0RCWUVfUkVBU09OX0RVUExJQ0FURRAD');

@$core.Deprecated('Use helloDescriptor instead')
const Hello$json = {
  '1': 'Hello',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.v1.DeviceInfo',
      '10': 'device'
    },
    {
      '1': 'features',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.ferret.v1.FeatureSupport',
      '10': 'features'
    },
    {'1': 'listen_port', '3': 3, '4': 1, '5': 13, '10': 'listenPort'},
    {'1': 'vpn_addresses', '3': 4, '4': 3, '5': 9, '10': 'vpnAddresses'},
    {
      '1': 'wants_vpn_addresses',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'wantsVpnAddresses'
    },
  ],
};

/// Descriptor for `Hello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List helloDescriptor = $convert.base64Decode(
    'CgVIZWxsbxItCgZkZXZpY2UYASABKAsyFS5mZXJyZXQudjEuRGV2aWNlSW5mb1IGZGV2aWNlEj'
    'UKCGZlYXR1cmVzGAIgAygLMhkuZmVycmV0LnYxLkZlYXR1cmVTdXBwb3J0UghmZWF0dXJlcxIf'
    'CgtsaXN0ZW5fcG9ydBgDIAEoDVIKbGlzdGVuUG9ydBIjCg12cG5fYWRkcmVzc2VzGAQgAygJUg'
    'x2cG5BZGRyZXNzZXMSLgoTd2FudHNfdnBuX2FkZHJlc3NlcxgFIAEoCFIRd2FudHNWcG5BZGRy'
    'ZXNzZXM=');

@$core.Deprecated('Use vpnReachDescriptor instead')
const VpnReach$json = {
  '1': 'VpnReach',
  '2': [
    {'1': 'wants_addresses', '3': 1, '4': 1, '5': 8, '10': 'wantsAddresses'},
    {
      '1': 'includes_addresses',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'includesAddresses'
    },
    {'1': 'addresses', '3': 3, '4': 3, '5': 9, '10': 'addresses'},
  ],
};

/// Descriptor for `VpnReach`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vpnReachDescriptor = $convert.base64Decode(
    'CghWcG5SZWFjaBInCg93YW50c19hZGRyZXNzZXMYASABKAhSDndhbnRzQWRkcmVzc2VzEi0KEm'
    'luY2x1ZGVzX2FkZHJlc3NlcxgCIAEoCFIRaW5jbHVkZXNBZGRyZXNzZXMSHAoJYWRkcmVzc2Vz'
    'GAMgAygJUglhZGRyZXNzZXM=');

@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = {
  '1': 'Ping',
  '2': [
    {'1': 'sent_at_ms', '3': 1, '4': 1, '5': 4, '10': 'sentAtMs'},
  ],
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor =
    $convert.base64Decode('CgRQaW5nEhwKCnNlbnRfYXRfbXMYASABKARSCHNlbnRBdE1z');

@$core.Deprecated('Use pongDescriptor instead')
const Pong$json = {
  '1': 'Pong',
  '2': [
    {'1': 'ping_sent_at_ms', '3': 1, '4': 1, '5': 4, '10': 'pingSentAtMs'},
  ],
};

/// Descriptor for `Pong`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pongDescriptor = $convert.base64Decode(
    'CgRQb25nEiUKD3Bpbmdfc2VudF9hdF9tcxgBIAEoBFIMcGluZ1NlbnRBdE1z');

@$core.Deprecated('Use presenceDescriptor instead')
const Presence$json = {
  '1': 'Presence',
  '2': [
    {'1': 'user_active', '3': 1, '4': 1, '5': 8, '10': 'userActive'},
    {'1': 'screen_on', '3': 2, '4': 1, '5': 8, '10': 'screenOn'},
    {'1': 'battery_percent', '3': 3, '4': 1, '5': 5, '10': 'batteryPercent'},
    {'1': 'charging', '3': 4, '4': 1, '5': 8, '10': 'charging'},
    {'1': 'away', '3': 5, '4': 1, '5': 8, '10': 'away'},
  ],
};

/// Descriptor for `Presence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceDescriptor = $convert.base64Decode(
    'CghQcmVzZW5jZRIfCgt1c2VyX2FjdGl2ZRgBIAEoCFIKdXNlckFjdGl2ZRIbCglzY3JlZW5fb2'
    '4YAiABKAhSCHNjcmVlbk9uEicKD2JhdHRlcnlfcGVyY2VudBgDIAEoBVIOYmF0dGVyeVBlcmNl'
    'bnQSGgoIY2hhcmdpbmcYBCABKAhSCGNoYXJnaW5nEhIKBGF3YXkYBSABKAhSBGF3YXk=');

@$core.Deprecated('Use goodbyeDescriptor instead')
const Goodbye$json = {
  '1': 'Goodbye',
  '2': [
    {
      '1': 'reason',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.GoodbyeReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `Goodbye`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List goodbyeDescriptor = $convert.base64Decode(
    'CgdHb29kYnllEjAKBnJlYXNvbhgBIAEoDjIYLmZlcnJldC52MS5Hb29kYnllUmVhc29uUgZyZW'
    'Fzb24=');
