// This is a generated file - do not edit.
//
// Generated from ferret/v1/envelope.proto.

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

@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = {
  '1': 'ErrorCode',
  '2': [
    {'1': 'ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'ERROR_CODE_UNSUPPORTED', '2': 1},
    {'1': 'ERROR_CODE_DENIED', '2': 2},
    {'1': 'ERROR_CODE_INVALID', '2': 3},
    {'1': 'ERROR_CODE_INTERNAL', '2': 4},
    {'1': 'ERROR_CODE_TIMEOUT', '2': 5},
    {'1': 'ERROR_CODE_CANCELLED', '2': 6},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode(
    'CglFcnJvckNvZGUSGgoWRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEhoKFkVSUk9SX0NPREVfVU'
    '5TVVBQT1JURUQQARIVChFFUlJPUl9DT0RFX0RFTklFRBACEhYKEkVSUk9SX0NPREVfSU5WQUxJ'
    'RBADEhcKE0VSUk9SX0NPREVfSU5URVJOQUwQBBIWChJFUlJPUl9DT0RFX1RJTUVPVVQQBRIYCh'
    'RFUlJPUl9DT0RFX0NBTkNFTExFRBAG');

@$core.Deprecated('Use envelopeDescriptor instead')
const Envelope$json = {
  '1': 'Envelope',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {'1': 'reply_to', '3': 2, '4': 1, '5': 4, '10': 'replyTo'},
    {'1': 'feature', '3': 3, '4': 1, '5': 9, '10': 'feature'},
    {'1': 'type', '3': 4, '4': 1, '5': 9, '10': 'type'},
    {'1': 'payload', '3': 5, '4': 1, '5': 12, '10': 'payload'},
    {
      '1': 'error',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.ferret.v1.Error',
      '10': 'error'
    },
  ],
};

/// Descriptor for `Envelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List envelopeDescriptor = $convert.base64Decode(
    'CghFbnZlbG9wZRIOCgJpZBgBIAEoBFICaWQSGQoIcmVwbHlfdG8YAiABKARSB3JlcGx5VG8SGA'
    'oHZmVhdHVyZRgDIAEoCVIHZmVhdHVyZRISCgR0eXBlGAQgASgJUgR0eXBlEhgKB3BheWxvYWQY'
    'BSABKAxSB3BheWxvYWQSJgoFZXJyb3IYBiABKAsyEC5mZXJyZXQudjEuRXJyb3JSBWVycm9y');

@$core.Deprecated('Use errorDescriptor instead')
const Error$json = {
  '1': 'Error',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.ErrorCode',
      '10': 'code'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `Error`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorDescriptor = $convert.base64Decode(
    'CgVFcnJvchIoCgRjb2RlGAEgASgOMhQuZmVycmV0LnYxLkVycm9yQ29kZVIEY29kZRIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdl');
