// This is a generated file - do not edit.
//
// Generated from ferret/camera/v1/camera.proto.

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

@$core.Deprecated('Use captureKindDescriptor instead')
const CaptureKind$json = {
  '1': 'CaptureKind',
  '2': [
    {'1': 'CAPTURE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CAPTURE_KIND_PHOTO', '2': 1},
    {'1': 'CAPTURE_KIND_DOCUMENT', '2': 2},
  ],
};

/// Descriptor for `CaptureKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List captureKindDescriptor = $convert.base64Decode(
    'CgtDYXB0dXJlS2luZBIcChhDQVBUVVJFX0tJTkRfVU5TUEVDSUZJRUQQABIWChJDQVBUVVJFX0'
    'tJTkRfUEhPVE8QARIZChVDQVBUVVJFX0tJTkRfRE9DVU1FTlQQAg==');

@$core.Deprecated('Use captureStatusDescriptor instead')
const CaptureStatus$json = {
  '1': 'CaptureStatus',
  '2': [
    {'1': 'CAPTURE_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'CAPTURE_STATUS_ASKING', '2': 1},
    {'1': 'CAPTURE_STATUS_TAKEN', '2': 2},
    {'1': 'CAPTURE_STATUS_DECLINED', '2': 3},
    {'1': 'CAPTURE_STATUS_CANCELLED', '2': 4},
    {'1': 'CAPTURE_STATUS_UNSUPPORTED', '2': 5},
    {'1': 'CAPTURE_STATUS_NO_PERMISSION', '2': 6},
    {'1': 'CAPTURE_STATUS_BUSY', '2': 7},
    {'1': 'CAPTURE_STATUS_FAILED', '2': 8},
    {'1': 'CAPTURE_STATUS_EXPIRED', '2': 9},
  ],
};

/// Descriptor for `CaptureStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List captureStatusDescriptor = $convert.base64Decode(
    'Cg1DYXB0dXJlU3RhdHVzEh4KGkNBUFRVUkVfU1RBVFVTX1VOU1BFQ0lGSUVEEAASGQoVQ0FQVF'
    'VSRV9TVEFUVVNfQVNLSU5HEAESGAoUQ0FQVFVSRV9TVEFUVVNfVEFLRU4QAhIbChdDQVBUVVJF'
    'X1NUQVRVU19ERUNMSU5FRBADEhwKGENBUFRVUkVfU1RBVFVTX0NBTkNFTExFRBAEEh4KGkNBUF'
    'RVUkVfU1RBVFVTX1VOU1VQUE9SVEVEEAUSIAocQ0FQVFVSRV9TVEFUVVNfTk9fUEVSTUlTU0lP'
    'ThAGEhcKE0NBUFRVUkVfU1RBVFVTX0JVU1kQBxIZChVDQVBUVVJFX1NUQVRVU19GQUlMRUQQCB'
    'IaChZDQVBUVVJFX1NUQVRVU19FWFBJUkVEEAk=');

@$core.Deprecated('Use captureRequestDescriptor instead')
const CaptureRequest$json = {
  '1': 'CaptureRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.camera.v1.CaptureKind',
      '10': 'kind'
    },
  ],
};

/// Descriptor for `CaptureRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureRequestDescriptor = $convert.base64Decode(
    'Cg5DYXB0dXJlUmVxdWVzdBIdCgpyZXF1ZXN0X2lkGAEgASgJUglyZXF1ZXN0SWQSMQoEa2luZB'
    'gCIAEoDjIdLmZlcnJldC5jYW1lcmEudjEuQ2FwdHVyZUtpbmRSBGtpbmQ=');

@$core.Deprecated('Use captureReplyDescriptor instead')
const CaptureReply$json = {
  '1': 'CaptureReply',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.camera.v1.CaptureStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `CaptureReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureReplyDescriptor = $convert.base64Decode(
    'CgxDYXB0dXJlUmVwbHkSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdWVzdElkEjcKBnN0YXR1cx'
    'gCIAEoDjIfLmZlcnJldC5jYW1lcmEudjEuQ2FwdHVyZVN0YXR1c1IGc3RhdHVz');

@$core.Deprecated('Use captureResultDescriptor instead')
const CaptureResult$json = {
  '1': 'CaptureResult',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.camera.v1.CaptureStatus',
      '10': 'status'
    },
    {'1': 'transfer_id', '3': 3, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'mime_type', '3': 4, '4': 1, '5': 9, '10': 'mimeType'},
  ],
};

/// Descriptor for `CaptureResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureResultDescriptor = $convert.base64Decode(
    'Cg1DYXB0dXJlUmVzdWx0Eh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3RJZBI3CgZzdGF0dX'
    'MYAiABKA4yHy5mZXJyZXQuY2FtZXJhLnYxLkNhcHR1cmVTdGF0dXNSBnN0YXR1cxIfCgt0cmFu'
    'c2Zlcl9pZBgDIAEoCVIKdHJhbnNmZXJJZBIbCgltaW1lX3R5cGUYBCABKAlSCG1pbWVUeXBl');

@$core.Deprecated('Use captureCancelDescriptor instead')
const CaptureCancel$json = {
  '1': 'CaptureCancel',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
  ],
};

/// Descriptor for `CaptureCancel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureCancelDescriptor = $convert.base64Decode(
    'Cg1DYXB0dXJlQ2FuY2VsEh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3RJZA==');
