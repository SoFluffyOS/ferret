// This is a generated file - do not edit.
//
// Generated from ferret/v1/wake.proto.

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

@$core.Deprecated('Use wakeLinkDescriptor instead')
const WakeLink$json = {
  '1': 'WakeLink',
  '2': [
    {'1': 'WAKE_LINK_UNSPECIFIED', '2': 0},
    {'1': 'WAKE_LINK_WIRED', '2': 1},
    {'1': 'WAKE_LINK_WIFI', '2': 2},
  ],
};

/// Descriptor for `WakeLink`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List wakeLinkDescriptor = $convert.base64Decode(
    'CghXYWtlTGluaxIZChVXQUtFX0xJTktfVU5TUEVDSUZJRUQQABITCg9XQUtFX0xJTktfV0lSRU'
    'QQARISCg5XQUtFX0xJTktfV0lGSRAC');

@$core.Deprecated('Use wakeSettingDescriptor instead')
const WakeSetting$json = {
  '1': 'WakeSetting',
  '2': [
    {'1': 'WAKE_SETTING_UNSPECIFIED', '2': 0},
    {'1': 'WAKE_SETTING_ON', '2': 1},
    {'1': 'WAKE_SETTING_OFF', '2': 2},
  ],
};

/// Descriptor for `WakeSetting`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List wakeSettingDescriptor = $convert.base64Decode(
    'CgtXYWtlU2V0dGluZxIcChhXQUtFX1NFVFRJTkdfVU5TUEVDSUZJRUQQABITCg9XQUtFX1NFVF'
    'RJTkdfT04QARIUChBXQUtFX1NFVFRJTkdfT0ZGEAI=');

@$core.Deprecated('Use wakeInfoDescriptor instead')
const WakeInfo$json = {
  '1': 'WakeInfo',
  '2': [
    {
      '1': 'interfaces',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.v1.WakeInterface',
      '10': 'interfaces'
    },
  ],
};

/// Descriptor for `WakeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wakeInfoDescriptor = $convert.base64Decode(
    'CghXYWtlSW5mbxI4CgppbnRlcmZhY2VzGAEgAygLMhguZmVycmV0LnYxLldha2VJbnRlcmZhY2'
    'VSCmludGVyZmFjZXM=');

@$core.Deprecated('Use wakeInterfaceDescriptor instead')
const WakeInterface$json = {
  '1': 'WakeInterface',
  '2': [
    {'1': 'mac', '3': 1, '4': 1, '5': 12, '10': 'mac'},
    {'1': 'address', '3': 2, '4': 1, '5': 9, '10': 'address'},
    {'1': 'broadcast', '3': 3, '4': 1, '5': 9, '10': 'broadcast'},
    {
      '1': 'link',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.WakeLink',
      '10': 'link'
    },
    {
      '1': 'setting',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.WakeSetting',
      '10': 'setting'
    },
  ],
};

/// Descriptor for `WakeInterface`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wakeInterfaceDescriptor = $convert.base64Decode(
    'Cg1XYWtlSW50ZXJmYWNlEhAKA21hYxgBIAEoDFIDbWFjEhgKB2FkZHJlc3MYAiABKAlSB2FkZH'
    'Jlc3MSHAoJYnJvYWRjYXN0GAMgASgJUglicm9hZGNhc3QSJwoEbGluaxgEIAEoDjITLmZlcnJl'
    'dC52MS5XYWtlTGlua1IEbGluaxIwCgdzZXR0aW5nGAUgASgOMhYuZmVycmV0LnYxLldha2VTZX'
    'R0aW5nUgdzZXR0aW5n');
