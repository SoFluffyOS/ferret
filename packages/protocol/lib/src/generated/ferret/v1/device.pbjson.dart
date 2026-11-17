// This is a generated file - do not edit.
//
// Generated from ferret/v1/device.proto.

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

@$core.Deprecated('Use platformDescriptor instead')
const Platform$json = {
  '1': 'Platform',
  '2': [
    {'1': 'PLATFORM_UNSPECIFIED', '2': 0},
    {'1': 'PLATFORM_ANDROID', '2': 1},
    {'1': 'PLATFORM_IOS', '2': 2},
    {'1': 'PLATFORM_MACOS', '2': 3},
    {'1': 'PLATFORM_LINUX', '2': 4},
    {'1': 'PLATFORM_WINDOWS', '2': 5},
    {'1': 'PLATFORM_BROWSER', '2': 6},
    {'1': 'PLATFORM_CLI', '2': 7},
  ],
};

/// Descriptor for `Platform`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List platformDescriptor = $convert.base64Decode(
    'CghQbGF0Zm9ybRIYChRQTEFURk9STV9VTlNQRUNJRklFRBAAEhQKEFBMQVRGT1JNX0FORFJPSU'
    'QQARIQCgxQTEFURk9STV9JT1MQAhISCg5QTEFURk9STV9NQUNPUxADEhIKDlBMQVRGT1JNX0xJ'
    'TlVYEAQSFAoQUExBVEZPUk1fV0lORE9XUxAFEhQKEFBMQVRGT1JNX0JST1dTRVIQBhIQCgxQTE'
    'FURk9STV9DTEkQBw==');

@$core.Deprecated('Use formFactorDescriptor instead')
const FormFactor$json = {
  '1': 'FormFactor',
  '2': [
    {'1': 'FORM_FACTOR_UNSPECIFIED', '2': 0},
    {'1': 'FORM_FACTOR_PHONE', '2': 1},
    {'1': 'FORM_FACTOR_TABLET', '2': 2},
    {'1': 'FORM_FACTOR_LAPTOP', '2': 3},
    {'1': 'FORM_FACTOR_DESKTOP', '2': 4},
    {'1': 'FORM_FACTOR_SERVER', '2': 5},
  ],
};

/// Descriptor for `FormFactor`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List formFactorDescriptor = $convert.base64Decode(
    'CgpGb3JtRmFjdG9yEhsKF0ZPUk1fRkFDVE9SX1VOU1BFQ0lGSUVEEAASFQoRRk9STV9GQUNUT1'
    'JfUEhPTkUQARIWChJGT1JNX0ZBQ1RPUl9UQUJMRVQQAhIWChJGT1JNX0ZBQ1RPUl9MQVBUT1AQ'
    'AxIXChNGT1JNX0ZBQ1RPUl9ERVNLVE9QEAQSFgoSRk9STV9GQUNUT1JfU0VSVkVSEAU=');

@$core.Deprecated('Use deviceInfoDescriptor instead')
const DeviceInfo$json = {
  '1': 'DeviceInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'platform',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.Platform',
      '10': 'platform'
    },
    {
      '1': 'form_factor',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.FormFactor',
      '10': 'formFactor'
    },
    {'1': 'model', '3': 5, '4': 1, '5': 9, '10': 'model'},
    {'1': 'app_version', '3': 6, '4': 1, '5': 9, '10': 'appVersion'},
    {'1': 'protocol_version', '3': 7, '4': 1, '5': 13, '10': 'protocolVersion'},
  ],
};

/// Descriptor for `DeviceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceInfoDescriptor = $convert.base64Decode(
    'CgpEZXZpY2VJbmZvEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEi8KCHBsYX'
    'Rmb3JtGAMgASgOMhMuZmVycmV0LnYxLlBsYXRmb3JtUghwbGF0Zm9ybRI2Cgtmb3JtX2ZhY3Rv'
    'chgEIAEoDjIVLmZlcnJldC52MS5Gb3JtRmFjdG9yUgpmb3JtRmFjdG9yEhQKBW1vZGVsGAUgAS'
    'gJUgVtb2RlbBIfCgthcHBfdmVyc2lvbhgGIAEoCVIKYXBwVmVyc2lvbhIpChBwcm90b2NvbF92'
    'ZXJzaW9uGAcgASgNUg9wcm90b2NvbFZlcnNpb24=');

@$core.Deprecated('Use featureSupportDescriptor instead')
const FeatureSupport$json = {
  '1': 'FeatureSupport',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'version', '3': 2, '4': 1, '5': 13, '10': 'version'},
    {'1': 'flags', '3': 3, '4': 3, '5': 9, '10': 'flags'},
  ],
};

/// Descriptor for `FeatureSupport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List featureSupportDescriptor = $convert.base64Decode(
    'Cg5GZWF0dXJlU3VwcG9ydBIOCgJpZBgBIAEoCVICaWQSGAoHdmVyc2lvbhgCIAEoDVIHdmVyc2'
    'lvbhIUCgVmbGFncxgDIAMoCVIFZmxhZ3M=');
