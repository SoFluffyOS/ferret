// This is a generated file - do not edit.
//
// Generated from ferret/v1/discovery.proto.

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

@$core.Deprecated('Use announceDescriptor instead')
const Announce$json = {
  '1': 'Announce',
  '2': [
    {'1': 'protocol_version', '3': 1, '4': 1, '5': 13, '10': 'protocolVersion'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'platform',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.Platform',
      '10': 'platform'
    },
    {
      '1': 'form_factor',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.FormFactor',
      '10': 'formFactor'
    },
    {'1': 'port', '3': 6, '4': 1, '5': 13, '10': 'port'},
    {'1': 'reply', '3': 7, '4': 1, '5': 8, '10': 'reply'},
  ],
};

/// Descriptor for `Announce`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announceDescriptor = $convert.base64Decode(
    'CghBbm5vdW5jZRIpChBwcm90b2NvbF92ZXJzaW9uGAEgASgNUg9wcm90b2NvbFZlcnNpb24SGw'
    'oJZGV2aWNlX2lkGAIgASgJUghkZXZpY2VJZBISCgRuYW1lGAMgASgJUgRuYW1lEi8KCHBsYXRm'
    'b3JtGAQgASgOMhMuZmVycmV0LnYxLlBsYXRmb3JtUghwbGF0Zm9ybRI2Cgtmb3JtX2ZhY3Rvch'
    'gFIAEoDjIVLmZlcnJldC52MS5Gb3JtRmFjdG9yUgpmb3JtRmFjdG9yEhIKBHBvcnQYBiABKA1S'
    'BHBvcnQSFAoFcmVwbHkYByABKAhSBXJlcGx5');
