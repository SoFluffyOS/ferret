// This is a generated file - do not edit.
//
// Generated from ferret/drop/v1/drop.proto.

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

@$core.Deprecated('Use declineReasonDescriptor instead')
const DeclineReason$json = {
  '1': 'DeclineReason',
  '2': [
    {'1': 'DECLINE_REASON_UNSPECIFIED', '2': 0},
    {'1': 'DECLINE_REASON_DECLINED', '2': 1},
    {'1': 'DECLINE_REASON_TIMEOUT', '2': 2},
    {'1': 'DECLINE_REASON_STORAGE', '2': 3},
    {'1': 'DECLINE_REASON_UNKNOWN_TRANSFER', '2': 4},
    {'1': 'DECLINE_REASON_INVALID', '2': 5},
  ],
};

/// Descriptor for `DeclineReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List declineReasonDescriptor = $convert.base64Decode(
    'Cg1EZWNsaW5lUmVhc29uEh4KGkRFQ0xJTkVfUkVBU09OX1VOU1BFQ0lGSUVEEAASGwoXREVDTE'
    'lORV9SRUFTT05fREVDTElORUQQARIaChZERUNMSU5FX1JFQVNPTl9USU1FT1VUEAISGgoWREVD'
    'TElORV9SRUFTT05fU1RPUkFHRRADEiMKH0RFQ0xJTkVfUkVBU09OX1VOS05PV05fVFJBTlNGRV'
    'IQBBIaChZERUNMSU5FX1JFQVNPTl9JTlZBTElEEAU=');

@$core.Deprecated('Use failureReasonDescriptor instead')
const FailureReason$json = {
  '1': 'FailureReason',
  '2': [
    {'1': 'FAILURE_REASON_UNSPECIFIED', '2': 0},
    {'1': 'FAILURE_REASON_CANCELLED', '2': 1},
    {'1': 'FAILURE_REASON_CHECKSUM', '2': 2},
    {'1': 'FAILURE_REASON_STORAGE', '2': 3},
    {'1': 'FAILURE_REASON_SOURCE_CHANGED', '2': 4},
    {'1': 'FAILURE_REASON_PROTOCOL', '2': 5},
    {'1': 'FAILURE_REASON_UNKNOWN_TRANSFER', '2': 6},
  ],
};

/// Descriptor for `FailureReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List failureReasonDescriptor = $convert.base64Decode(
    'Cg1GYWlsdXJlUmVhc29uEh4KGkZBSUxVUkVfUkVBU09OX1VOU1BFQ0lGSUVEEAASHAoYRkFJTF'
    'VSRV9SRUFTT05fQ0FOQ0VMTEVEEAESGwoXRkFJTFVSRV9SRUFTT05fQ0hFQ0tTVU0QAhIaChZG'
    'QUlMVVJFX1JFQVNPTl9TVE9SQUdFEAMSIQodRkFJTFVSRV9SRUFTT05fU09VUkNFX0NIQU5HRU'
    'QQBBIbChdGQUlMVVJFX1JFQVNPTl9QUk9UT0NPTBAFEiMKH0ZBSUxVUkVfUkVBU09OX1VOS05P'
    'V05fVFJBTlNGRVIQBg==');

@$core.Deprecated('Use fileInfoDescriptor instead')
const FileInfo$json = {
  '1': 'FileInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'size', '3': 2, '4': 1, '5': 4, '10': 'size'},
    {'1': 'mime', '3': 3, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'sha256', '3': 4, '4': 1, '5': 12, '10': 'sha256'},
  ],
};

/// Descriptor for `FileInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileInfoDescriptor = $convert.base64Decode(
    'CghGaWxlSW5mbxISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHNpemUYAiABKARSBHNpemUSEgoEbW'
    'ltZRgDIAEoCVIEbWltZRIWCgZzaGEyNTYYBCABKAxSBnNoYTI1Ng==');

@$core.Deprecated('Use transferOfferDescriptor instead')
const TransferOffer$json = {
  '1': 'TransferOffer',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {
      '1': 'files',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.ferret.drop.v1.FileInfo',
      '10': 'files'
    },
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'chunk_size', '3': 4, '4': 1, '5': 13, '10': 'chunkSize'},
  ],
};

/// Descriptor for `TransferOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferOfferDescriptor = $convert.base64Decode(
    'Cg1UcmFuc2Zlck9mZmVyEh8KC3RyYW5zZmVyX2lkGAEgASgJUgp0cmFuc2ZlcklkEi4KBWZpbG'
    'VzGAIgAygLMhguZmVycmV0LmRyb3AudjEuRmlsZUluZm9SBWZpbGVzEhIKBHRleHQYAyABKAlS'
    'BHRleHQSHQoKY2h1bmtfc2l6ZRgEIAEoDVIJY2h1bmtTaXpl');

@$core.Deprecated('Use transferAnswerDescriptor instead')
const TransferAnswer$json = {
  '1': 'TransferAnswer',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'accepted', '3': 2, '4': 1, '5': 8, '10': 'accepted'},
    {
      '1': 'reason',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.drop.v1.DeclineReason',
      '10': 'reason'
    },
    {'1': 'file_index', '3': 4, '4': 1, '5': 13, '10': 'fileIndex'},
    {'1': 'offset', '3': 5, '4': 1, '5': 4, '10': 'offset'},
  ],
};

/// Descriptor for `TransferAnswer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferAnswerDescriptor = $convert.base64Decode(
    'Cg5UcmFuc2ZlckFuc3dlchIfCgt0cmFuc2Zlcl9pZBgBIAEoCVIKdHJhbnNmZXJJZBIaCghhY2'
    'NlcHRlZBgCIAEoCFIIYWNjZXB0ZWQSNQoGcmVhc29uGAMgASgOMh0uZmVycmV0LmRyb3AudjEu'
    'RGVjbGluZVJlYXNvblIGcmVhc29uEh0KCmZpbGVfaW5kZXgYBCABKA1SCWZpbGVJbmRleBIWCg'
    'ZvZmZzZXQYBSABKARSBm9mZnNldA==');

@$core.Deprecated('Use chunkDescriptor instead')
const Chunk$json = {
  '1': 'Chunk',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_index', '3': 2, '4': 1, '5': 13, '10': 'fileIndex'},
    {'1': 'offset', '3': 3, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'data', '3': 4, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Chunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chunkDescriptor = $convert.base64Decode(
    'CgVDaHVuaxIfCgt0cmFuc2Zlcl9pZBgBIAEoCVIKdHJhbnNmZXJJZBIdCgpmaWxlX2luZGV4GA'
    'IgASgNUglmaWxlSW5kZXgSFgoGb2Zmc2V0GAMgASgEUgZvZmZzZXQSEgoEZGF0YRgEIAEoDFIE'
    'ZGF0YQ==');

@$core.Deprecated('Use chunkReceivedDescriptor instead')
const ChunkReceived$json = {
  '1': 'ChunkReceived',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_index', '3': 2, '4': 1, '5': 13, '10': 'fileIndex'},
    {'1': 'offset', '3': 3, '4': 1, '5': 4, '10': 'offset'},
  ],
};

/// Descriptor for `ChunkReceived`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chunkReceivedDescriptor = $convert.base64Decode(
    'Cg1DaHVua1JlY2VpdmVkEh8KC3RyYW5zZmVyX2lkGAEgASgJUgp0cmFuc2ZlcklkEh0KCmZpbG'
    'VfaW5kZXgYAiABKA1SCWZpbGVJbmRleBIWCgZvZmZzZXQYAyABKARSBm9mZnNldA==');

@$core.Deprecated('Use fileCompleteDescriptor instead')
const FileComplete$json = {
  '1': 'FileComplete',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_index', '3': 2, '4': 1, '5': 13, '10': 'fileIndex'},
    {'1': 'sha256', '3': 3, '4': 1, '5': 12, '10': 'sha256'},
  ],
};

/// Descriptor for `FileComplete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileCompleteDescriptor = $convert.base64Decode(
    'CgxGaWxlQ29tcGxldGUSHwoLdHJhbnNmZXJfaWQYASABKAlSCnRyYW5zZmVySWQSHQoKZmlsZV'
    '9pbmRleBgCIAEoDVIJZmlsZUluZGV4EhYKBnNoYTI1NhgDIAEoDFIGc2hhMjU2');

@$core.Deprecated('Use fileVerifiedDescriptor instead')
const FileVerified$json = {
  '1': 'FileVerified',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_index', '3': 2, '4': 1, '5': 13, '10': 'fileIndex'},
    {'1': 'ok', '3': 3, '4': 1, '5': 8, '10': 'ok'},
    {
      '1': 'reason',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.drop.v1.FailureReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `FileVerified`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileVerifiedDescriptor = $convert.base64Decode(
    'CgxGaWxlVmVyaWZpZWQSHwoLdHJhbnNmZXJfaWQYASABKAlSCnRyYW5zZmVySWQSHQoKZmlsZV'
    '9pbmRleBgCIAEoDVIJZmlsZUluZGV4Eg4KAm9rGAMgASgIUgJvaxI1CgZyZWFzb24YBCABKA4y'
    'HS5mZXJyZXQuZHJvcC52MS5GYWlsdXJlUmVhc29uUgZyZWFzb24=');

@$core.Deprecated('Use transferCompleteDescriptor instead')
const TransferComplete$json = {
  '1': 'TransferComplete',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
  ],
};

/// Descriptor for `TransferComplete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferCompleteDescriptor = $convert.base64Decode(
    'ChBUcmFuc2ZlckNvbXBsZXRlEh8KC3RyYW5zZmVyX2lkGAEgASgJUgp0cmFuc2Zlcklk');

@$core.Deprecated('Use cancelDescriptor instead')
const Cancel$json = {
  '1': 'Cancel',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {
      '1': 'reason',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.drop.v1.FailureReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `Cancel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelDescriptor = $convert.base64Decode(
    'CgZDYW5jZWwSHwoLdHJhbnNmZXJfaWQYASABKAlSCnRyYW5zZmVySWQSNQoGcmVhc29uGAIgAS'
    'gOMh0uZmVycmV0LmRyb3AudjEuRmFpbHVyZVJlYXNvblIGcmVhc29u');

@$core.Deprecated('Use resumeRequestDescriptor instead')
const ResumeRequest$json = {
  '1': 'ResumeRequest',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_index', '3': 2, '4': 1, '5': 13, '10': 'fileIndex'},
    {'1': 'offset', '3': 3, '4': 1, '5': 4, '10': 'offset'},
  ],
};

/// Descriptor for `ResumeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resumeRequestDescriptor = $convert.base64Decode(
    'Cg1SZXN1bWVSZXF1ZXN0Eh8KC3RyYW5zZmVyX2lkGAEgASgJUgp0cmFuc2ZlcklkEh0KCmZpbG'
    'VfaW5kZXgYAiABKA1SCWZpbGVJbmRleBIWCgZvZmZzZXQYAyABKARSBm9mZnNldA==');
