// This is a generated file - do not edit.
//
// Generated from ferret/actions/v1/actions.proto.

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

@$core.Deprecated('Use actionKindDescriptor instead')
const ActionKind$json = {
  '1': 'ActionKind',
  '2': [
    {'1': 'ACTION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'ACTION_KIND_SLEEP', '2': 1},
    {'1': 'ACTION_KIND_RESTART', '2': 2},
    {'1': 'ACTION_KIND_SHUT_DOWN', '2': 3},
    {'1': 'ACTION_KIND_MUTE', '2': 4},
    {'1': 'ACTION_KIND_VOLUME_UP', '2': 5},
    {'1': 'ACTION_KIND_VOLUME_DOWN', '2': 6},
    {'1': 'ACTION_KIND_CUSTOM', '2': 7},
  ],
};

/// Descriptor for `ActionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List actionKindDescriptor = $convert.base64Decode(
    'CgpBY3Rpb25LaW5kEhsKF0FDVElPTl9LSU5EX1VOU1BFQ0lGSUVEEAASFQoRQUNUSU9OX0tJTk'
    'RfU0xFRVAQARIXChNBQ1RJT05fS0lORF9SRVNUQVJUEAISGQoVQUNUSU9OX0tJTkRfU0hVVF9E'
    'T1dOEAMSFAoQQUNUSU9OX0tJTkRfTVVURRAEEhkKFUFDVElPTl9LSU5EX1ZPTFVNRV9VUBAFEh'
    'sKF0FDVElPTl9LSU5EX1ZPTFVNRV9ET1dOEAYSFgoSQUNUSU9OX0tJTkRfQ1VTVE9NEAc=');

@$core.Deprecated('Use runResultDescriptor instead')
const RunResult$json = {
  '1': 'RunResult',
  '2': [
    {'1': 'RUN_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'RUN_RESULT_DONE', '2': 1},
    {'1': 'RUN_RESULT_DENIED', '2': 2},
    {'1': 'RUN_RESULT_NOT_ANSWERED', '2': 3},
    {'1': 'RUN_RESULT_BUSY', '2': 4},
    {'1': 'RUN_RESULT_TURNED_OFF', '2': 5},
    {'1': 'RUN_RESULT_UNKNOWN_ACTION', '2': 6},
    {'1': 'RUN_RESULT_FAILED', '2': 7},
    {'1': 'RUN_RESULT_CANCELLED', '2': 8},
    {'1': 'RUN_RESULT_TIMED_OUT', '2': 9},
  ],
};

/// Descriptor for `RunResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List runResultDescriptor = $convert.base64Decode(
    'CglSdW5SZXN1bHQSGgoWUlVOX1JFU1VMVF9VTlNQRUNJRklFRBAAEhMKD1JVTl9SRVNVTFRfRE'
    '9ORRABEhUKEVJVTl9SRVNVTFRfREVOSUVEEAISGwoXUlVOX1JFU1VMVF9OT1RfQU5TV0VSRUQQ'
    'AxITCg9SVU5fUkVTVUxUX0JVU1kQBBIZChVSVU5fUkVTVUxUX1RVUk5FRF9PRkYQBRIdChlSVU'
    '5fUkVTVUxUX1VOS05PV05fQUNUSU9OEAYSFQoRUlVOX1JFU1VMVF9GQUlMRUQQBxIYChRSVU5f'
    'UkVTVUxUX0NBTkNFTExFRBAIEhgKFFJVTl9SRVNVTFRfVElNRURfT1VUEAk=');

@$core.Deprecated('Use actionDescriptor instead')
const Action$json = {
  '1': 'Action',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.actions.v1.ActionKind',
      '10': 'kind'
    },
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'confirm', '3': 4, '4': 1, '5': 8, '10': 'confirm'},
  ],
};

/// Descriptor for `Action`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionDescriptor = $convert.base64Decode(
    'CgZBY3Rpb24SDgoCaWQYASABKAlSAmlkEjEKBGtpbmQYAiABKA4yHS5mZXJyZXQuYWN0aW9ucy'
    '52MS5BY3Rpb25LaW5kUgRraW5kEhQKBXRpdGxlGAMgASgJUgV0aXRsZRIYCgdjb25maXJtGAQg'
    'ASgIUgdjb25maXJt');

@$core.Deprecated('Use actionListDescriptor instead')
const ActionList$json = {
  '1': 'ActionList',
  '2': [
    {
      '1': 'actions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.actions.v1.Action',
      '10': 'actions'
    },
  ],
};

/// Descriptor for `ActionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionListDescriptor = $convert.base64Decode(
    'CgpBY3Rpb25MaXN0EjMKB2FjdGlvbnMYASADKAsyGS5mZXJyZXQuYWN0aW9ucy52MS5BY3Rpb2'
    '5SB2FjdGlvbnM=');

@$core.Deprecated('Use runActionDescriptor instead')
const RunAction$json = {
  '1': 'RunAction',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `RunAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runActionDescriptor =
    $convert.base64Decode('CglSdW5BY3Rpb24SDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use runActionReplyDescriptor instead')
const RunActionReply$json = {
  '1': 'RunActionReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.actions.v1.RunResult',
      '10': 'result'
    },
    {
      '1': 'exit_code',
      '3': 2,
      '4': 1,
      '5': 17,
      '9': 0,
      '10': 'exitCode',
      '17': true
    },
  ],
  '8': [
    {'1': '_exit_code'},
  ],
};

/// Descriptor for `RunActionReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runActionReplyDescriptor = $convert.base64Decode(
    'Cg5SdW5BY3Rpb25SZXBseRI0CgZyZXN1bHQYASABKA4yHC5mZXJyZXQuYWN0aW9ucy52MS5SdW'
    '5SZXN1bHRSBnJlc3VsdBIgCglleGl0X2NvZGUYAiABKBFIAFIIZXhpdENvZGWIAQFCDAoKX2V4'
    'aXRfY29kZQ==');
