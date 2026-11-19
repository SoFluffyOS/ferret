// This is a generated file - do not edit.
//
// Generated from ferret/wake/v1/wake.proto.

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

@$core.Deprecated('Use wakeResultDescriptor instead')
const WakeResult$json = {
  '1': 'WakeResult',
  '2': [
    {'1': 'WAKE_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'WAKE_RESULT_SENT', '2': 1},
    {'1': 'WAKE_RESULT_NOT_PAIRED', '2': 2},
    {'1': 'WAKE_RESULT_RELAY_OFF', '2': 3},
    {'1': 'WAKE_RESULT_NO_INFO', '2': 4},
    {'1': 'WAKE_RESULT_FAILED', '2': 5},
  ],
};

/// Descriptor for `WakeResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List wakeResultDescriptor = $convert.base64Decode(
    'CgpXYWtlUmVzdWx0EhsKF1dBS0VfUkVTVUxUX1VOU1BFQ0lGSUVEEAASFAoQV0FLRV9SRVNVTF'
    'RfU0VOVBABEhoKFldBS0VfUkVTVUxUX05PVF9QQUlSRUQQAhIZChVXQUtFX1JFU1VMVF9SRUxB'
    'WV9PRkYQAxIXChNXQUtFX1JFU1VMVF9OT19JTkZPEAQSFgoSV0FLRV9SRVNVTFRfRkFJTEVEEA'
    'U=');

@$core.Deprecated('Use wakeRequestDescriptor instead')
const WakeRequest$json = {
  '1': 'WakeRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {
      '1': 'info',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ferret.v1.WakeInfo',
      '10': 'info'
    },
    {'1': 'last_address', '3': 3, '4': 1, '5': 9, '10': 'lastAddress'},
  ],
};

/// Descriptor for `WakeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wakeRequestDescriptor = $convert.base64Decode(
    'CgtXYWtlUmVxdWVzdBIbCglkZXZpY2VfaWQYASABKAlSCGRldmljZUlkEicKBGluZm8YAiABKA'
    'syEy5mZXJyZXQudjEuV2FrZUluZm9SBGluZm8SIQoMbGFzdF9hZGRyZXNzGAMgASgJUgtsYXN0'
    'QWRkcmVzcw==');

@$core.Deprecated('Use wakeReplyDescriptor instead')
const WakeReply$json = {
  '1': 'WakeReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.wake.v1.WakeResult',
      '10': 'result'
    },
  ],
};

/// Descriptor for `WakeReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wakeReplyDescriptor = $convert.base64Decode(
    'CglXYWtlUmVwbHkSMgoGcmVzdWx0GAEgASgOMhouZmVycmV0Lndha2UudjEuV2FrZVJlc3VsdF'
    'IGcmVzdWx0');
