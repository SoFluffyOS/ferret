// This is a generated file - do not edit.
//
// Generated from ferret/find/v1/find.proto.

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

@$core.Deprecated('Use ringStateDescriptor instead')
const RingState$json = {
  '1': 'RingState',
  '2': [
    {'1': 'RING_STATE_UNSPECIFIED', '2': 0},
    {'1': 'RING_STATE_RINGING', '2': 1},
    {'1': 'RING_STATE_STOPPED', '2': 2},
  ],
};

/// Descriptor for `RingState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List ringStateDescriptor = $convert.base64Decode(
    'CglSaW5nU3RhdGUSGgoWUklOR19TVEFURV9VTlNQRUNJRklFRBAAEhYKElJJTkdfU1RBVEVfUk'
    'lOR0lORxABEhYKElJJTkdfU1RBVEVfU1RPUFBFRBAC');

@$core.Deprecated('Use stopReasonDescriptor instead')
const StopReason$json = {
  '1': 'StopReason',
  '2': [
    {'1': 'STOP_REASON_UNSPECIFIED', '2': 0},
    {'1': 'STOP_REASON_FOUND', '2': 1},
    {'1': 'STOP_REASON_TIMEOUT', '2': 2},
    {'1': 'STOP_REASON_STOPPED_REMOTELY', '2': 3},
    {'1': 'STOP_REASON_FAILED', '2': 4},
  ],
};

/// Descriptor for `StopReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List stopReasonDescriptor = $convert.base64Decode(
    'CgpTdG9wUmVhc29uEhsKF1NUT1BfUkVBU09OX1VOU1BFQ0lGSUVEEAASFQoRU1RPUF9SRUFTT0'
    '5fRk9VTkQQARIXChNTVE9QX1JFQVNPTl9USU1FT1VUEAISIAocU1RPUF9SRUFTT05fU1RPUFBF'
    'RF9SRU1PVEVMWRADEhYKElNUT1BfUkVBU09OX0ZBSUxFRBAE');

@$core.Deprecated('Use ringRequestDescriptor instead')
const RingRequest$json = {
  '1': 'RingRequest',
  '2': [
    {'1': 'duration_seconds', '3': 1, '4': 1, '5': 13, '10': 'durationSeconds'},
    {'1': 'override_silent', '3': 2, '4': 1, '5': 8, '10': 'overrideSilent'},
  ],
};

/// Descriptor for `RingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ringRequestDescriptor = $convert.base64Decode(
    'CgtSaW5nUmVxdWVzdBIpChBkdXJhdGlvbl9zZWNvbmRzGAEgASgNUg9kdXJhdGlvblNlY29uZH'
    'MSJwoPb3ZlcnJpZGVfc2lsZW50GAIgASgIUg5vdmVycmlkZVNpbGVudA==');

@$core.Deprecated('Use stopRingRequestDescriptor instead')
const StopRingRequest$json = {
  '1': 'StopRingRequest',
};

/// Descriptor for `StopRingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopRingRequestDescriptor =
    $convert.base64Decode('Cg9TdG9wUmluZ1JlcXVlc3Q=');

@$core.Deprecated('Use ringStatusDescriptor instead')
const RingStatus$json = {
  '1': 'RingStatus',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.find.v1.RingState',
      '10': 'state'
    },
    {
      '1': 'reason',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.find.v1.StopReason',
      '10': 'reason'
    },
    {'1': 'remaining_ms', '3': 3, '4': 1, '5': 13, '10': 'remainingMs'},
    {'1': 'muted', '3': 4, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `RingStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ringStatusDescriptor = $convert.base64Decode(
    'CgpSaW5nU3RhdHVzEi8KBXN0YXRlGAEgASgOMhkuZmVycmV0LmZpbmQudjEuUmluZ1N0YXRlUg'
    'VzdGF0ZRIyCgZyZWFzb24YAiABKA4yGi5mZXJyZXQuZmluZC52MS5TdG9wUmVhc29uUgZyZWFz'
    'b24SIQoMcmVtYWluaW5nX21zGAMgASgNUgtyZW1haW5pbmdNcxIUCgVtdXRlZBgEIAEoCFIFbX'
    'V0ZWQ=');

@$core.Deprecated('Use getRingInfoDescriptor instead')
const GetRingInfo$json = {
  '1': 'GetRingInfo',
};

/// Descriptor for `GetRingInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRingInfoDescriptor =
    $convert.base64Decode('CgtHZXRSaW5nSW5mbw==');

@$core.Deprecated('Use ringInfoDescriptor instead')
const RingInfo$json = {
  '1': 'RingInfo',
  '2': [
    {'1': 'ringing', '3': 1, '4': 1, '5': 8, '10': 'ringing'},
    {'1': 'rings_when_silent', '3': 2, '4': 1, '5': 8, '10': 'ringsWhenSilent'},
    {'1': 'needs_app_open', '3': 3, '4': 1, '5': 8, '10': 'needsAppOpen'},
    {'1': 'needs_permission', '3': 4, '4': 1, '5': 8, '10': 'needsPermission'},
  ],
};

/// Descriptor for `RingInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ringInfoDescriptor = $convert.base64Decode(
    'CghSaW5nSW5mbxIYCgdyaW5naW5nGAEgASgIUgdyaW5naW5nEioKEXJpbmdzX3doZW5fc2lsZW'
    '50GAIgASgIUg9yaW5nc1doZW5TaWxlbnQSJAoObmVlZHNfYXBwX29wZW4YAyABKAhSDG5lZWRz'
    'QXBwT3BlbhIpChBuZWVkc19wZXJtaXNzaW9uGAQgASgIUg9uZWVkc1Blcm1pc3Npb24=');
