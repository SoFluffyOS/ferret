// This is a generated file - do not edit.
//
// Generated from ferret/clipboard/v1/clipboard.proto.

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

@$core.Deprecated('Use clipKindDescriptor instead')
const ClipKind$json = {
  '1': 'ClipKind',
  '2': [
    {'1': 'CLIP_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CLIP_KIND_TEXT', '2': 1},
    {'1': 'CLIP_KIND_IMAGE', '2': 2},
    {'1': 'CLIP_KIND_URL', '2': 3},
  ],
};

/// Descriptor for `ClipKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List clipKindDescriptor = $convert.base64Decode(
    'CghDbGlwS2luZBIZChVDTElQX0tJTkRfVU5TUEVDSUZJRUQQABISCg5DTElQX0tJTkRfVEVYVB'
    'ABEhMKD0NMSVBfS0lORF9JTUFHRRACEhEKDUNMSVBfS0lORF9VUkwQAw==');

@$core.Deprecated('Use clipItemDescriptor instead')
const ClipItem$json = {
  '1': 'ClipItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.clipboard.v1.ClipKind',
      '10': 'kind'
    },
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'image', '3': 4, '4': 1, '5': 12, '10': 'image'},
    {'1': 'image_mime', '3': 5, '4': 1, '5': 9, '10': 'imageMime'},
    {'1': 'created_at_ms', '3': 6, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'source_device_id', '3': 7, '4': 1, '5': 9, '10': 'sourceDeviceId'},
    {'1': 'sensitive', '3': 8, '4': 1, '5': 8, '10': 'sensitive'},
    {'1': 'content_hash', '3': 9, '4': 1, '5': 12, '10': 'contentHash'},
  ],
};

/// Descriptor for `ClipItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clipItemDescriptor = $convert.base64Decode(
    'CghDbGlwSXRlbRIOCgJpZBgBIAEoCVICaWQSMQoEa2luZBgCIAEoDjIdLmZlcnJldC5jbGlwYm'
    '9hcmQudjEuQ2xpcEtpbmRSBGtpbmQSEgoEdGV4dBgDIAEoCVIEdGV4dBIUCgVpbWFnZRgEIAEo'
    'DFIFaW1hZ2USHQoKaW1hZ2VfbWltZRgFIAEoCVIJaW1hZ2VNaW1lEiIKDWNyZWF0ZWRfYXRfbX'
    'MYBiABKANSC2NyZWF0ZWRBdE1zEigKEHNvdXJjZV9kZXZpY2VfaWQYByABKAlSDnNvdXJjZURl'
    'dmljZUlkEhwKCXNlbnNpdGl2ZRgIIAEoCFIJc2Vuc2l0aXZlEiEKDGNvbnRlbnRfaGFzaBgJIA'
    'EoDFILY29udGVudEhhc2g=');

@$core.Deprecated('Use clipPushDescriptor instead')
const ClipPush$json = {
  '1': 'ClipPush',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.clipboard.v1.ClipItem',
      '10': 'item'
    },
    {'1': 'expires_in_ms', '3': 2, '4': 1, '5': 3, '10': 'expiresInMs'},
  ],
};

/// Descriptor for `ClipPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clipPushDescriptor = $convert.base64Decode(
    'CghDbGlwUHVzaBIxCgRpdGVtGAEgASgLMh0uZmVycmV0LmNsaXBib2FyZC52MS5DbGlwSXRlbV'
    'IEaXRlbRIiCg1leHBpcmVzX2luX21zGAIgASgDUgtleHBpcmVzSW5Ncw==');
